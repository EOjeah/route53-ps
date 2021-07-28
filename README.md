# Route53-PS

Repository to follow along the course [AWS Networking Deep Dive: Route 53 DNS](https://app.pluralsight.com/library/courses/aws-networking-deep-dive-route-53-dns/table-of-contents) by Ben Piper on Pluralsight.

Code follow along via git tags

![route53-tags](./images/route53-tags.png)

## Steps

1. To use, first you need to create the unique delegation set id which would help assign 4 AWS DNS servers.
   Navigate to `route53-ps/delegation-set`

    Initialise terraform with `terraform init`

    > ⓘ
    > You need to have configured your AWS credentials for the account you want the resources to get created in. Visit [aws docs](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html) for more information

    Run `terraform plan` and confirm your output. if you are happy with the output, run `terraform apply`

    ```bash
    user@PC route53/delegation-set $ terraform init
    user@PC route53/delegation-set $ terraform plan
    user@PC route53/delegation-set $ terraform apply
    outputs:
        delegation_set_id = "N0193805L3AX0CH0SN8B"
    ```

2. Create Resources!

    Use the output from `step 1` above and replace this terraform resource in [main.tf](https://github.com/EOjeah/route53-ps/blob/10.2/main.tf#L338) with the `delegation_set_id` output string

    ```js
    data "aws_route53_delegation_set" "main" {
        id = "N0193805L3AX0CH0SN8B"
    }
    ```

    Navigate to the root directory where main.tf file exists then run terraform plan and apply

    ```bash
    user@PC route53 $ terraform init
    user@PC route53 $ terraform plan
    user@PC route53 $ terraform apply
    Plan: 39 to add, 0 to change, 0 to destroy.

    Changes to Outputs:
    + caller-reference = [
        + "ns-0.awsdns-10.com",
        + "ns-1.awsdns-20.org",
        + "ns-2.awsdns-30.co.uk",
        + "ns-3.awsdns-50.net",
      ]
    + delegation-setid = "N0193805L3AX0CH0SN8B"
    + east-1-public-ip = (known after apply)
    + east-2-public-ip = (known after apply)
    + west-1-public-ip = (known after apply)
    + west-2-public-ip = (known after apply)

    Do you want to perform these actions?
    Terraform will perform the actions described above.
    Only 'yes' will be accepted to approve.

    Enter a value: yes
    ```

3. Destroy Resources

    When you are done, and need to save cost on your AWS account, simply destroy your resources (in main.tf), leave the delegation set id, destroying these will give 4 different AWS DNS servers on apply

    ```bash
    user@PC route53 $ terraform init
    user@PC route53 $ terraform plan
    user@PC route53 $ terraform destroy
    Plan: 0 to add, 0 to change, 39 to destroy.
    ```

---

Pick up where you left up by running terraform apply in root directory and all the resources
will get created with the same AWS DNS servers

---
