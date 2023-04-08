variable "bucket_name" {
  description = "El nombre del bucket S3"
  type        = string
}

variable "path_to_manifest" {
  description = "La ruta al archivo manifest.json"
  type        = string
}

variable "path_to_openapi" {
  description = "La ruta al archivo openapi.json"
  type        = string
}

variable "path_to_lambda" {
  description = "La ruta al archivo lambda.zip"
  type        = string
}

variable "lambda_runtime" {
  description = "El runtime de la función Lambda"
  type        = string
}

variable "lambda_handler" {
  description = "El handler de la función Lambda"
  type        = string
}
