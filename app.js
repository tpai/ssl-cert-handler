require('dotenv').config();

const AWS = require('aws-sdk');
AWS.config.update({
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    region: process.env.AWS_REGION
});

const dynamodb = new AWS.DynamoDB();

const DYNAMODB_SEARCH_KEY = process.env.DYNAMODB_SEARCH_KEY;
const DYNAMODB_VALUE_KEY = process.env.DYNAMODB_VALUE_KEY;
const DYNAMODB_TABLE = process.env.DYNAMODB_TABLE;

module.exports = (req, res, match) => {
    if (match.hasOwnProperty(DYNAMODB_SEARCH_KEY)) {
        dynamodb.getItem(
            { Key: { [DYNAMODB_SEARCH_KEY]: { S: match.token } }, TableName: DYNAMODB_TABLE },
            (err, data) => {
                if (err)
                    res.status(404).send(err);
                else
                    res.status(200).send(data.Item[DYNAMODB_VALUE_KEY].S);
            }
        );
    } else {
        res.sendStatus(400);
    }
};
