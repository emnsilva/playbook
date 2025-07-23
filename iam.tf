# Configura o provedor OIDC para GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"] # Thumbprint do GitHub (atualizado em 2023)
}

# Política de confiança (quem pode assumir essa role)
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Restringe apenas para tokens do GitHub Actions
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Restringe para repositórios específicos (substitua pelo seu org/repo)
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:emnsilva/playbook:*"] # Exemplo: "repo:octocat/my-app:*"
    }
  }
}

# Cria a IAM Role
resource "aws_iam_role" "github_actions" {
  name               = "github-actions-role"
  description        = "Role usada pelo GitHub Actions para deploy na AWS"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json
}

# Permissões para ECR (ajuste conforme sua necessidade)
data "aws_iam_policy_document" "ecr_access" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]
    resources = ["*"]
  }
}

# Cria a política customizada para ECR
resource "aws_iam_policy" "ecr_policy" {
  name        = "GitHubActionsECRAccess"
  description = "Permissão para push/pull de imagens no ECR"
  policy      = data.aws_iam_policy_document.ecr_access.json
}

# Anexa a política à role
resource "aws_iam_role_policy_attachment" "ecr_access" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}

# Output com o ARN da role (útil para o GitHub Actions)
output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
