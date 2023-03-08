#!/usr/bin/env bats
# Copyright (c) 2023 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

load "../lib/utils"
load "../lib/detik"

# shellcheck disable=SC2034 # these variables are used by detik
DETIK_CLIENT_NAME="kubectl"
# shellcheck disable=SC2034
DETIK_CLIENT_NAMESPACE="iff"
# shellcheck disable=SC2034
DEBUG_DETIK="true"


@test "verify that bsqls object has been created" {
    run verify "there is 1 bsqls named 'shacl-validation'"
    [ "$status" -eq 0 ]
}

@test "verify that bsqls object is deployed successfully" {

    run try "at most 30 times every 60s to find 1 bsqls named 'shacl-validation' with 'status.state' being 'RUNNING'"
    [ "$status" -eq 0 ]
}
