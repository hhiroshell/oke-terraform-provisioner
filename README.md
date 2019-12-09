これはなに
==========
OKE(Oracle Containter Engine for Kubernetes)をプロビジョニングするTerraformテンプレートです。


前提条件
--------

- Oracle Cloudのアカウントを取得済みであること
- Unix互換のシェル環境
- Terraform 0.12+ （OCI Resource Managerを利用する場合は不要）


目次
====

1. このTerraformテンプレートの利用手順
2. パラメータのリファレンス


1 . このTerraformテンプレートの利用手順
=======================================


1.1. OCI Resource ManagerからTerraformを実行する場合
----------------------------------------------------
OCI Resource Manager（以下、OCI RM）からこのテンプレートを実行する場合、テンプレートをまとめた.zipアーカイブを作成する必要があります。これを行うため、以下のコマンドを実行してください。

    > ./build.sh

アーカイブは``[リポジトリのトップ]/target/oke-private-cluster.zip``に作成されます。OCI RMのコンソールで、このアーカイブを指定してスタックの作製を行ってください。

OCI RMスタックで変数を指定することで、OKEクラスターの構成を変更することができます（一部はOCI RMの使用により非対応）。変数の詳細は[2. パラメータのリファレンス]を参照してください。


1.2. OCI Resource Managerを使わず、通常の手順でTerraformを実行する場合
----------------------------------------------------------------------
はじめにOKEクラスターの構成を``terraform.tfvars``に設定を記述して調整します。ベースとなるパラメータファイルをコピーして、これを編集していきます。

    > cp terraform.tfvars.example terraform.tfvars
    > vim terraform.tfvars

パラメータの詳細は[2. パラメータのリファレンス]を参照してください。

以下、パラメータファイルの記述例です。

```properties
# OCI Provider
tenancy_ocid = "ocid1.tenancy.oc1..aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
user_ocid = "ocid1.user.oc1..aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
fingerprint = "aa:aa:aa:aa:aa:aa:aa:aa:aa:aa:aa:aa:aa:aa:aa:aa"
private_key_path = "../secrets/oci_api_key.pem"
region = "ap-tokyo-1"

# Resource Name Prefix
oke_resource_prefix = "test"

# Target Compartment
compartment_ocid = "ocid1.compartment.oc1..aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

# Run on the OCI Resource Manager
on_resource_manager = false

# OKE Cluster
oke_kubernetes_version = "v1.13.5"
oke_kubernetes_dashboard_enabled = false
oke_helm_tiller_enabled = false

# OKE Node Pool
oke_kubernetes_node_version = "v1.13.5"
oke_node_pool_node_image_name = "Oracle-Linux-7.6"
oke_node_pool_shape = [
    "VM.Standard.E2.1"
]
oke_node_pool_quantity = [
    2
]
```

このテンプレートを実行するため、始めに``terraform init``でプラグイン等を含めた初期化を行う必要があります。

    > terraform init
    …
    Terraform has been successfully initialized!

続いて``terraform plan``を実行します(dry run)。

    > terraform plan
    ...
    Plan: 13 to add, 0 to change, 0 to destroy.

この時点では、まだ実際の環境構築は行われていません。ここまで特にエラーなく進んでいれば、最後に``terraform apply``を実行して環境の構築を開始します（構築にはしばらく時間がかかります）。

    > terraform apply

kubectlの設定ファイルは、このテンプレートを実行したときに自動で生成されています。パスは``[リポジトリのトップ]/generated/kubeconfig``です。

例えば、環境変数[KUBECONFIG]に設定ファイルのパスを指定すると、作成したクラスターに対してkubectlが実行できるようになります。

    > export KUBECONFIG=~/terraform-oke-provisioner/generated/kubeconfig

クラスターの一般情報を取得するコマンドで、動作を確認してみます。以下のような応答が返れば、正常にクラスターにアクセスできています。

    > kubectl cluster-info
    Kubernetes master is running at https://xxx.xxx.xxx.xxx:443
    KubeDNS is running at https://xxx.xxx.xxx.xxx:443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
    
    To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

クラスターを削除する場合は、``terraform destroy``を実行します。

    > terraform destroy

この操作により、クラスターを含む、この章で作成した全てのリソースが削除されます。
``terraform apply``を再度実行すると、同等の設定のクラスターを同じように作成することができます。


2 . パラメータのリファレンス
============================

- 実行方法の指定

|key                    |value                                                                                                                          |OCI RMで指定可能   |
|---                    |---                                                                                                                            |---                |
|on\_resource\_manager  |このテンプレ―の実行環境。OCI RMで諒する場合はtureにします。これにより、RMでサポートされないリソースの作成をスキップします。   |true               |

- Oracle Cloudへの接続情報

|key                 |value                                             |OCI RMで指定可能   |
|---                 |---                                               |---                |
|tenancy\_ocid       |OCIのテナントのOCID                               |true               |
|compartment\_ocid   |OKEをプロビジョニングするコンパートメントのOCID   |true               |
|region              |データセンターのリージョン                        |true               |
|user\_ocid          |OCIのアカウントのOCID                             |false              |
|fingerprint         |APIアクセスキーのFingerprint                      |false              |
|private\_key\_path  |APIアクセスキー                                   |false              |

- OKEクラスターの構成情報

|key                                    |value                                                                                      |OCI RMで指定可能   |
|---                                    |---                                                                                        |---                |
|oke\_resource\_prefix                  |OKEと関連リソースの名前につけるプレフィックス                                              |true               |
|oke\_kubernetes\_version               |API ServerのKubernetesのバージョン                                                         |true               |
|oke\_kubernetes\_dashboard\_enabled    |Kubernetesのダッシュボードをデプロイするかどうか                                           |true               |
|oke\_helm\_tiller\_enabled             |Helm Tillerをデプロイするかどうか                                                          |true               |
|oke\_kubernetes\_node\_version         |Worker NodeのKubernetesのバージョン                                                        |true               |
|oke\_node\_pool\_node\_image\_name     |Worker NodeのOSイメージ名                                                                  |true               |
|oke\_node\_pool\_shape                 |Node Pool内に作るNodeのシェイプ。配列で複数指定すると複数のNode Poolを作成可能             |false              |
|oke\_node\_pool\_quantity              |Node PoolのNode数。oke\_node\_pool\_shapeで複数指定した場合は、対応する位置に値を設定する  |false              |


以上。
