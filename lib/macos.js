'use strict';
const path = require('path');
const {promisify} = require('util');
const childProcess = require('child_process');

const execFile = promisify(childProcess.execFile);
const bin = path.join(__dirname, '../bin/ActiveWinHelper');

const parseMac = stdout => {
	try {
		const result = JSON.parse(stdout);
		if (result !== null) {
			result.platform = 'macos';
			return result;
		}
	} catch (error) {
		console.error(stdout);
		console.error(error);
		return {};
	}
};

module.exports = async () => {
	const {stdout} = await execFile(bin);
	return parseMac(stdout);
};

module.exports.sync = () => parseMac(childProcess.execFileSync(bin, {encoding: 'utf8'}));
