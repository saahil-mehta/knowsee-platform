# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# NOTE: Project IAM members use google_project_iam_member (additive) rather than
# google_project_iam_binding (authoritative). This is safer as it won't override
# existing IAM bindings on the project.

resource "google_project_iam_member" "project_iam_members" {
  for_each = var.project_iam_members

  project = each.value.project
  role    = each.value.role
  member  = each.value.member
}
