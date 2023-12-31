resource "aws_apprunner_service" "service" {
  service_name = "${var.prefix}-apprunner"



  instance_configuration {
    cpu = "256"
    memory  = "1024"

    instance_role_arn = aws_iam_role.role_for_apprunner_service.arn

  }

  source_configuration {
    authentication_configuration {
      access_role_arn = "arn:aws:iam::244530008913:role/service-role/AppRunnerECRAccessRole"
    }
    image_repository {

      image_configuration {
        port = var.port
      }
      image_identifier      = var.image
      image_repository_type = "ECR"

    }
    auto_deployments_enabled = true
  }
}

resource "aws_iam_role" "role_for_apprunner_service" {
  name               = "ApprunnerS3RekognitionCWAccessRole${var.prefix}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}


data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["tasks.apprunner.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
# add Policy to Role
resource "aws_iam_role_policy_attachment" "attachment" {
  role       = aws_iam_role.role_for_apprunner_service.name
  policy_arn = aws_iam_policy.policy.arn
}
# Creete polcy using given polcy document
resource "aws_iam_policy" "policy" {
  name        = "RekognitionImageRolePolicy${var.prefix}"
  description = "Policy for apprunner instance to use rekognition, cloudwatch and S3 bucket"
  policy      = data.aws_iam_policy_document.policy_document.json
}

# Create a Policy document whit given Permissions
data "aws_iam_policy_document" "policy_document" {
  statement {
    effect    = "Allow"
    actions   = ["rekognition:*"]
    resources = ["*"]
  }

  statement  {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }

  statement  {
    effect    = "Allow"
    actions   = ["cloudwatch:*"]
    resources = ["*"]
  }

}
# Import local module from ./alarm_module
module "threshold_alarm" {
  source = "./alarm_module"
  email = var.email
  prefix = var.prefix
  metric_name = var.metric_name
  threshold = var.threshold

}
