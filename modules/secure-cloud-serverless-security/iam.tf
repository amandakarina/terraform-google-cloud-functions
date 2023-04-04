/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  roles_serverless_administrator          = var.groups.group_serverless_administrator == null ? [] : ["roles/run.admin", "roles/cloudfunctions.admin", "roles/compute.networkViewer", "roles/compute.networkUser"]
  roles_serverless_security_administrator = var.groups.group_serverless_security_administrator == null ? [] : ["roles/run.viewer", "roles/cloudfunctions.viewer", "roles/cloudkms.viewer", "roles/artifactregistry.reader"]
  roles_group_cloud_function_developer    = var.groups.group_cloud_function_developer == null ? [] : ["roles/cloudfunctions.developer", "roles/artifactregistry.writer", "cloudkms.cryptoKeyEncrypter"]
  roles_group_cloud_function_user         = var.groups.group_cloud_function_user == null ? [] : ["cloudfunctions.invoker", "run.invoker"]
}


resource "google_project_iam_member" "group_serverless_administrator_admin" {
  for_each = toset(local.roles_serverless_administrator)

  project = var.serverless_project_id
  role    = each.value
  member  = "group:${var.groups.group_serverless_administrator}"
}

resource "google_project_iam_member" "group_serverless_security_administrator_viewer" {
  for_each = toset(local.roles_serverless_security_administrator)

  project = var.kms_project_id
  role    = each.value
  member  = "group:${var.groups.group_serverless_security_administrator}"
}


resource "google_project_iam_member" "group_cloud_function_developer_run_developer" {
  for_each = toset(local.roles_group_cloud_function_developer)

  project = var.kms_project_id
  role    = each.value
  member  = "group:${var.groups.group_cloud_function_developer}"
}

resource "google_project_iam_member" "group_cloud_function_user_run_invoker" {
  for_each = toset(local.roles_group_cloud_function_user)

  project = var.serverless_project_id
  role    = each.value
  member  = "group:${var.groups.group_cloud_function_user}"
}
