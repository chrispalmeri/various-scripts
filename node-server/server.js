// no dependency node server, run like:
// `node server.js`
// `node server.js 3000`
// `node server.js 3000 www`
// also `npm start` is an alias for `node server.js` when no start script is defined

import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import buffer from 'node:buffer';

const dir = import.meta.dirname;
const args = process.argv.slice(2);

const httpPort = args[0] ?? 4000;
const httpRoot = args[1] ?? '.';

// if you need more mime types you can search here
// https://cdn.jsdelivr.net/gh/jshttp/mime-db@master/db.json

const mimeTypes = {
	'.html': 'text/html',
	'.css': 'text/css',
	'.js': 'text/javascript',
	'.md': 'text/markdown',
	'.csv': 'text/csv',
	'.ico': 'image/x-icon',
	'.jpg': 'image/jpeg',
	'.png': 'image/png',
	'.webp': 'image/webp',
	'.gif': 'image/gif',
	'.svg': 'image/svg+xml',
	'.mp3': 'audio/mpeg',
	'.flac': 'audio/flac',
	'.m4a': 'audio/mp4',
	'.wav': 'audio/wav',
	'.ogg': 'audio/ogg',
	'.mp4': 'video/mp4',
	'.m4v': 'video/mp4',
	'.woff2': 'font/woff2',
	'.woff': 'font/woff',
	'.ttf': 'font/ttf',
	'.json': 'application/json',
	'.xml': 'application/xml',
	'.webmanifest': 'application/manifest+json',
	'.rss': 'application/rss+xml',
	'.pdf': 'application/pdf',
	'.zip': 'application/zip',
	'.db': 'application/vnd.sqlite3'
};

const server = http.createServer('request', (request, response) => {
	const location = new URL('http://' + request.headers.host + request.url);

	let file = path.join(dir, httpRoot, decodeURIComponent(location.pathname));

	if (file.slice(-1) === path.sep) {
		file += 'index.html';
	}

	fs.readFile(file, (error, data) => {
		if (!error) {
			let contentType = mimeTypes[path.extname(file)];

			if (buffer.isUtf8(data)) {
				contentType ??= 'text/plain';
				contentType += ';charset=utf-8';
			} else {
				contentType ??= 'application/octet-stream';
			}

			response.statusCode = 200;
			response.setHeader('Content-Type', contentType);
			response.end(data);
		} else {
			switch (error.code) {
				case 'ENOENT':
					response.statusCode = 404;
					break;
				case 'EISDIR':
					location.pathname += '/';
					response.statusCode = 307;
					response.setHeader('Location', location.href);
					break;
				default:
					response.statusCode = 500;
					console.log(error.code, file);
			}

			response.end();
		}
	});
});

server.listen(httpPort, () => {
	console.log(`Server started: http://localhost:${httpPort}/`);
});
