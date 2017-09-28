require('dotenv').config();

const express = require('express');
const { createServer } = require('http');
const { parse } = require('url');
const route = require('path-match')({
    sensitive: false,
    strict: false,
    end: false
});
const app = require('./app');

const expressServer = express();
createServer(expressServer).listen(3000, err => {
    expressServer.use((req, res) => {
        const { pathname } = parse(req.url, true);
        if (pathname === '/') {
            res.sendStatus(200);
        } else {
            const match = route('/.well-known/acme-challenge/:token')(pathname);
            app(req, res, match);
        }
    });
});
