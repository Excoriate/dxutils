package main

import (
	"context"
	"errors"
	"fmt"
	"github.com/aws/aws-sdk-go-v2/aws"
	awsCfg "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	typesDyn "github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
	"github.com/aws/smithy-go"
	"github.com/hashicorp/go-hclog"
	"os"
)

var logger = hclog.New(&hclog.LoggerOptions{
	Name:  "4id-aws-boostrap",
	Level: hclog.LevelFromString("DEBUG"),
})

const bucketName = "platform-tfstate-account-master"
const lockTableName = "platform-tfstate-account-master"

func log(input string, err error) {
	if err != nil {
		logger.Error(input, "error", err)
	} else {
		logger.Info(input)
	}
}

func createTFStateBucket(cfg aws.Config) {
	svc := s3.NewFromConfig(cfg)

	_, err := svc.HeadBucket(context.TODO(), &s3.HeadBucketInput{
		Bucket: aws.String(bucketName),
	})
	bucketPolicyReformed := `{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DenyIncorrectEncryptionHeader",
            "Effect": "Deny",
            "Principal": {
                "AWS": "*"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::platform-tfstate-account-master/*",
            "Condition": {
                "StringNotEquals": {
                    "s3:x-amz-server-side-encryption": [
                        "AES256",
                        "aws:kms"
                    ]
                }
            }
        },
        {
            "Sid": "DenyUnEncryptedObjectUploads",
            "Effect": "Deny",
            "Principal": {
                "AWS": "*"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::platform-tfstate-account-master/*",
            "Condition": {
                "Null": {
                    "s3:x-amz-server-side-encryption": "true"
                }
            }
        },
        {
            "Sid": "EnforceTlsRequestsOnly",
            "Effect": "Deny",
            "Principal": {
                "AWS": "*"
            },
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::platform-tfstate-account-master/*",
                "arn:aws:s3:::platform-tfstate-account-master"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
`

	if err != nil {
		var apiError smithy.APIError
		if errors.As(err, &apiError) {
			switch apiError.(type) {
			case *types.NotFound:
				log(fmt.Sprintf("Bucket %s is available.\n", bucketName), nil)
				err = nil
			default:
				log(fmt.Sprintf("Either you don't have access to bucket %s or another error"+
					" occurred. "+
					"Here's what happened: \n", bucketName), err)
			}
		}
	} else {
		log(fmt.Sprintf("Bucket %v exists and you already own it.", bucketName), nil)
		return
	}

	// Create the bucket with the desired properties
	params := &s3.CreateBucketInput{
		Bucket: aws.String(bucketName),
		ACL:    types.BucketCannedACLPrivate,
		CreateBucketConfiguration: &types.CreateBucketConfiguration{
			LocationConstraint: types.BucketLocationConstraintEuCentral1,
		},
		ObjectLockEnabledForBucket: true,
	}

	result, err := svc.CreateBucket(context.TODO(), params)

	if err != nil {
		log("failed to create bucket", err)
		os.Exit(1)
	}

	log(fmt.Sprintf("Bucket %s created successfully at %s 🚀", bucketName, result.Location), nil)

	permissions := &s3.PutBucketPolicyInput{
		Bucket: aws.String(bucketName),
		Policy: aws.String(bucketPolicyReformed),
	}

	_, err = svc.PutBucketPolicy(context.TODO(), permissions)

	if err != nil {
		log("failed to set bucket policy", err)
		// if policy failed, rollback and kill the bucket.
		_, err = svc.DeleteBucket(context.TODO(), &s3.DeleteBucketInput{
			Bucket: aws.String(bucketName),
		})

		if err != nil {
			log("failed to delete bucket", err)
			os.Exit(1)
		}

		log(fmt.Sprintf("Bucket %s deleted successfully", bucketName), nil)

		os.Exit(1)
	}

	log("Bucket policy set successfully ✅", nil)

	blockAll := &s3.PutPublicAccessBlockInput{
		Bucket: aws.String(bucketName),
		PublicAccessBlockConfiguration: &types.PublicAccessBlockConfiguration{
			BlockPublicAcls:       true,
			BlockPublicPolicy:     true,
			IgnorePublicAcls:      true,
			RestrictPublicBuckets: true,
		},
	}

	_, err = svc.PutPublicAccessBlock(context.TODO(), blockAll)

	if err != nil {
		log("failed to set public access block", err)
		os.Exit(1)
	}

	log("Public access block set successfully ✅", nil)
	log("S3 bucket created successfully ✅", nil)
}

func createLockTable(cfg aws.Config) {
	client := dynamodb.NewFromConfig(cfg)

	input := &dynamodb.CreateTableInput{
		TableName: aws.String(lockTableName),
		AttributeDefinitions: []typesDyn.AttributeDefinition{
			{
				AttributeName: aws.String("LockID"),
				AttributeType: typesDyn.ScalarAttributeTypeS,
			},
		},
		KeySchema: []typesDyn.KeySchemaElement{
			{
				AttributeName: aws.String("LockID"),
				KeyType:       typesDyn.KeyTypeHash,
			},
		},
		BillingMode: typesDyn.BillingModePayPerRequest,
		//ProvisionedThroughput: &typesDyn.ProvisionedThroughput{
		//	ReadCapacityUnits:  aws.Int64(1),
		//	WriteCapacityUnits: aws.Int64(1),
		//},
	}

	_, err := client.DescribeTable(context.TODO(), &dynamodb.DescribeTableInput{
		TableName: aws.String(lockTableName),
	})

	if err != nil {
		var apiError smithy.APIError
		if errors.As(err, &apiError) {
			switch apiError.(type) {
			case *typesDyn.ResourceNotFoundException:
				log(fmt.Sprintf("Table %s is available.\n", lockTableName), nil)

				_, err = client.CreateTable(context.TODO(), input)
				if err != nil {
					log("failed to create table", err)
					os.Exit(1)
				}

				log("Table created successfully ✅", nil)
			default:
				log(fmt.Sprintf("Either you don't have access to table %s or another error"+
					" occurred. "+
					"Here's what happened: \n", lockTableName), err)
				os.Exit(1)
			}
		}
	}

	log(fmt.Sprintf("Table %s exists and you already own it.", lockTableName), nil)
	return
}

func main() {
	if os.Getenv("AWS_ACCESS_KEY_ID") == "" {
		log("AWS_ACCESS_KEY_ID is not set", nil)
		os.Exit(1)
	}

	if os.Getenv("AWS_SECRET_ACCESS_KEY") == "" {
		log("AWS_SECRET_ACCESS_KEY is not set", nil)
		os.Exit(1)
	}

	cfg, err := awsCfg.LoadDefaultConfig(context.TODO(), awsCfg.WithRegion("eu-central-1"))

	if err != nil {
		log("failed to load config", err)
		os.Exit(1)
	}

	// 1. Create bucket.
	createTFStateBucket(cfg)

	// 2. Create DynamoDB table.
	createLockTable(cfg)
}
