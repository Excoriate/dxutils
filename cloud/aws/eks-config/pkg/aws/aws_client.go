package aws

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/eks"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

var (
	homeDir, _        = os.UserHomeDir()
	profileNameFormat = "[%s]"
)

const (
	awsSecretAccessKeyPropertyName = "aws_secret_access_key"
	awsAccessKeyPropertyName       = "aws_access_key_id"
	awsSessionTokenPropertyName    = "aws_session_token"
	awsSecurityTokenPropertyName   = "aws_security_token"
	awsRegionPropertyName          = "region"
)

type EKSCluster struct {
	Name string
}

type Client interface {
	ListEKSs() []EKSCluster
	FetchAWSProfilesFromConfigFile() ([]Profile, error)
	ResolveAWSConfigFilePath() (string, error)
	GetAWSClient(awsProfileName Profile) (aws.Config, error)
	LookupAWSProfileNameInCredentialsFile(awsProfiles []Profile, awsProfileName string) (Profile, error)
}

type ClientImpl struct {
	awsProfileName     string
	awsCredentialsFile string
	awsClient          aws.Config
	awsProfile         Profile
}

type Profile struct {
	ProfileName     string
	AccessKeyID     string
	SecretAccessKey string
	SessionToken    string
	SecurityToken   string
	Region          string
}

func New(awsProfileName string) *ClientImpl {
	return &ClientImpl{
		awsProfileName:     awsProfileName,
		awsCredentialsFile: fmt.Sprintf("%s/.aws/credentials", homeDir),
	}
}

func (c *ClientImpl) ResolveAWSConfigFilePath() (string, error) {
	configPath := c.awsCredentialsFile

	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		return "", errors.New("AWS config file not found")
	}

	return configPath, nil
}

func (c *ClientImpl) LookupAWSProfileNameInCredentialsFile(awsProfiles []Profile,
	awsProfileName string) (Profile, error) {
	for _, profile := range awsProfiles {
		if profile.ProfileName == awsProfileName {
			if profile.Region == "" {
				profile.Region = "us-east-1"
			}
			c.awsProfile = profile
			return profile, nil
		}
	}

	return Profile{}, errors.New(fmt.Sprintf("AWS profile %s not found in credentials file", awsProfileName))
}

func (c *ClientImpl) FetchAWSProfilesFromConfigFile() ([]Profile, error) {
	file, err := os.Open(c.awsCredentialsFile)
	if err != nil {
		return nil, err
	}

	var allCredentials []Profile
	defer file.Close()

	scanner := bufio.NewScanner(file)
	credential := new(Profile)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.Contains(line, "[") && strings.Contains(line, "]") {

			profileName := strings.Replace(line, "[", "", -1)
			profileName = strings.Replace(profileName, "]", "", -1)

			credential.ProfileName = profileName
		}

		if strings.Contains(line, awsAccessKeyPropertyName) {
			credential.AccessKeyID = strings.Split(line, "=")[1]
		}

		if strings.Contains(line, awsSecretAccessKeyPropertyName) {
			credential.SecretAccessKey = strings.Split(line, "=")[1]
		}

		if strings.Contains(line, awsSessionTokenPropertyName) {
			credential.SessionToken = strings.Split(line, "=")[1]
		}

		if strings.Contains(line, awsSecurityTokenPropertyName) {
			credential.SecurityToken = strings.Split(line, "=")[1]
		}

		if strings.Contains(line, awsRegionPropertyName) {
			credential.Region = strings.Split(line, "=")[1]
		}

		if line == "" {
			allCredentials = append(allCredentials, *credential)
			credential = new(Profile)
		}
	}

	return allCredentials, nil
}

func (c *ClientImpl) GetAWSClient(awsProfile Profile) (aws.Config, error) {
	awsConfig, err := config.LoadDefaultConfig(context.TODO(),
		config.WithSharedConfigProfile(awsProfile.ProfileName), config.WithRegion(awsProfile.Region))
	if err != nil {
		log.Fatal("Unable to create AWS client, loading configuration from file.", err)
	}

	// Sanity check. If the token is expired,
	//a 403 will be thrown. A tiny check whether my creds are active.
	// Scan s3 buckets for this account.
	s3Client := s3.NewFromConfig(awsConfig)
	_, err = s3Client.ListBuckets(context.TODO(), &s3.ListBucketsInput{})
	if err != nil {
		return aws.Config{}, errors.New("AWS credentials expired. Please refresh them")
	}

	c.awsClient = awsConfig
	return awsConfig, nil
}

func (c *ClientImpl) ListEKSs() []EKSCluster {
	svc := eks.NewFromConfig(c.awsClient)

	resp, err := svc.ListClusters(context.TODO(), &eks.ListClustersInput{
		MaxResults: aws.Int32(20),
	})

	if err != nil {
		log.Fatalf("unable to list clusters, %v", err)
	}

	var eksClusters []EKSCluster
	for _, cluster := range resp.Clusters {
		eksClusters = append(eksClusters, EKSCluster{Name: cluster})
	}

	return eksClusters
}
