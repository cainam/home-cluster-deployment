// Copyright © 2024 Ory Corp
// SPDX-License-Identifier: Apache-2.0

import { Configuration, V0alpha2Api } from "@ory/client"
// import fs from 'node:fs';
//const fs = require('node:fs');
const fs = require('fs');

export const u = fs.readFileSync(process.env.mount_path+'/username', 'utf8');
export const p = fs.readFileSync(process.env.mount_path+'/password', 'utf8');

const baseOptions: any = {}

if (process.env.MOCK_TLS_TERMINATION) {
  baseOptions.headers = { "X-Forwarded-Proto": "https" }
}

const configuration = new Configuration({
  basePath: process.env.HYDRA_ADMIN_URL,
  accessToken: process.env.ORY_API_KEY || process.env.ORY_PAT,
  baseOptions,
})

const hydraAdmin = new V0alpha2Api(configuration)

export { hydraAdmin }
