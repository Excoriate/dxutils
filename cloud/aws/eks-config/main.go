package main

import (
	"github.com/Excoriate/dxutils/eksconfig/pkg/aws"
	"log"
	"os"
)

func main() {
	awsProfile := os.Getenv("AWS_PROFILE")
	if awsProfile == "" {
		log.Fatalf("AWS_PROFILE environment variable is not set")
	}

	awsCfg := aws.New(awsProfile)
	profileFile, err := awsCfg.ResolveAWSConfigFilePath()
	if err != nil {
		log.Fatal(err.Error())
	}

	log.Printf("AWS config file path: %s", profileFile)

	awsProfiles, err := awsCfg.FetchAWSProfilesFromConfigFile()
	if err != nil {
		log.Fatal(err.Error())
	}

	log.Printf("AWS profiles: %v", awsProfiles)

	profile, err := awsCfg.LookupAWSProfileNameInCredentialsFile(awsProfiles, awsProfile)
	if err != nil {
		log.Fatalf(err.Error())
	}

	_, err = awsCfg.GetAWSClient(profile)
	if err != nil {
		log.Fatalf("Failed to get AWS client: %v", err)
	}

	eksClusters := awsCfg.ListEKSs()
	log.Printf("EKS clusters: %v", eksClusters)
}
