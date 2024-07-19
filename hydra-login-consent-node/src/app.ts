// Copyright © 2024 Ory Corp
// SPDX-License-Identifier: Apache-2.0

import express, { NextFunction, Response, Request } from "express"
import path from "path"
import logger from "morgan"
import cookieParser from "cookie-parser"
import bodyParser from "body-parser"

import routes from "./routes"
import login from "./routes/login"
import logout from "./routes/logout"
import consent from "./routes/consent"

import fs from 'node:fs';
const u = fs.readFileSync(process.env.mount_path+'/username', 'utf8');
const p = fs.readFileSync(process.env.mount_path+'/password', 'utf8');


const app = express()
const morgan = require("morgan");

// view engine setup
app.set("views", path.join(__dirname, "..", "views"))
app.set("view engine", "pug")

// uncomment after placing your favicon in /public
//app.use(favicon(path.join(__dirname, 'public', 'favicon.ico')));
app.use(logger("dev"))
//
/*
 * morgan.token('id', function getId (req: Request) {
  return req.id
})

//app.use(morgan(':id :method :url :response-time'))

app.use(
morgan(function (tokens, req: Request, res: Response<MyResponseBody, MyResponseLocals>) {
  return [
    tokens.method(req, res),
    tokens.url(req, res),
    tokens.status(req, res),
    tokens.res(req, res, 'content-length'), '-',
    tokens['response-time'](req, res), 'ms'
  ].join(' ')
})
)
*/
//app.use(morgan('combined'))


app.use(bodyParser.json())
app.use(bodyParser.urlencoded({ extended: false }))
app.use(cookieParser())
app.use(express.static(path.join(__dirname, "public")))

app.use("/", routes)
app.use("/login", login)
app.use("/logout", logout)
app.use("/consent", consent)

// catch 404 and forward to error handler
app.use((req, res, next) => {
  next(new Error("Not Found"))
})

// error handlers

// development error handler
// will print stacktrace
if (app.get("env") === "development") {
  app.use((err: Error, req: Request, res: Response) => {
    res.status(500)
    res.render("error", {
      message: err.message,
      error: err,
    })
  })
}

// production error handler
// no stacktraces leaked to user
app.use((err: Error, req: Request, res: Response) => {
  res.status(500)
  res.render("error", {
    message: err.message,
    error: {},
  })
})

app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error(err.stack)
  res.status(500).render("error", {
    message: JSON.stringify(err, null, 2),
  })
})

const listenOn = Number(process.env.PORT || 3000)
app.listen(listenOn, () => {
  console.log(`Aha!!! Listening on http://0.0.0.0:${listenOn}`)
})
