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
	const {error, stdout} = await execFile(bin, {encoding: 'utf8'});
	if (error) {
		console.error(`error returned ${JSON.stringify(error)} ${stdout}`);
		return {};
	}

	return parseMac(stdout);
};

module.exports.sync = () => {
	try {
		const stdout = childProcess.execFileSync(bin, {encoding: 'utf8'});
		return parseMac(stdout);
	} catch (error) {
		console.error(`error returned ${JSON.stringify(error)}`);
		return {};
	}
};
