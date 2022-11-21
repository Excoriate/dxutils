package kubernetes

import (
	"errors"
	"fmt"
	"os"
)

const (
	KubeConfigFileName = "eks_config"
	KubeConfigPath     = ".kube"
)

var (
	homeDir, _ = os.UserHomeDir()
)

type EKSConfig interface {
	ValidateKubeConfigDir() string
	ListKubeConfigExistingSettings() []string
	GenerateNewKubeConfigs() error
}

type EKSCluster struct {
	Name string
}

type EKSConfigImpl struct {
	Region         string
	Clusters       []EKSCluster
	AWSProfileName string
	KubeConfigPath string
}

func New(region string, awsProfileName string) *EKSConfigImpl {
	return &EKSConfigImpl{
		Region:         region,
		AWSProfileName: awsProfileName,
		KubeConfigPath: fmt.Sprintf("%s/%s", homeDir, KubeConfigPath),
	}
}

func (e *EKSConfigImpl) ValidateKubeConfigDir() error {
	if _, err := os.Stat(e.KubeConfigPath); os.IsNotExist(err) {
		return fmt.Errorf("kube config directory not found: %s", e.KubeConfigPath)
	}
	return nil
}

func (e *EKSConfigImpl) ListKubeConfigExistingSettings() ([]string, error) {
	kubeConfigPath := e.KubeConfigPath
	kubeConfigFiles, err := os.ReadDir(kubeConfigPath)

	if err != nil {
		return nil, errors.New("failed to read kube config directory")
	}

	var kubeConfigs []string
	for _, kubeConfigFile := range kubeConfigFiles {
		kubeConfigs = append(kubeConfigs, kubeConfigFile.Name())
	}

	return kubeConfigs, nil
}

func (e *EKSConfigImpl) GenerateNewKubeConfigs() error {
	return nil
}
