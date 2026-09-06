#!/usr/bin/env node
/**
 * Export Firestore database using Firebase CLI auth token + REST API.
 * Usage: node tool/export_db.js
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'super-planner-app-3af40';
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

async function getAccessToken() {
  console.log('🔑 Getting access token from Firebase CLI...');
  const token = execSync('npx -y firebase-tools@latest login:use --token 2>nul || echo ""', { encoding: 'utf-8' }).trim();
  
  // Use the CI token approach - get token via firebase internals
  const configDir = process.env.APPDATA
    ? path.join(process.env.APPDATA, 'firebase')
    : path.join(process.env.HOME, '.config', 'firebase');
  
  const configFiles = [
    path.join(configDir, 'config.json'),
    path.join(process.env.APPDATA || '', 'configstore', 'firebase-tools.json'),
  ];

  for (const configFile of configFiles) {
    try {
      if (fs.existsSync(configFile)) {
        const config = JSON.parse(fs.readFileSync(configFile, 'utf-8'));
        const refreshToken = config.tokens?.refresh_token || config.user?.tokens?.refresh_token;
        if (refreshToken) {
          console.log(`   Found refresh token in ${path.basename(configFile)}`);
          // Exchange refresh token for access token
          const resp = await fetch('https://securetoken.googleapis.com/v1/token?key=AIzaSyDummy', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: `grant_type=refresh_token&refresh_token=${refreshToken}`,
          });
          if (resp.ok) {
            const data = await resp.json();
            return data.access_token;
          }
        }
      }
    } catch (e) {
      // try next
    }
  }

  // Fallback: use gcloud-style token from firebase
  const accessToken = execSync('npx -y firebase-tools@latest login:ci --no-localhost 2>nul', { encoding: 'utf-8' }).trim();
  return accessToken;
}

async function fetchWithToken(url, token) {
  const resp = await fetch(url, {
    headers: { 'Authorization': `Bearer ${token}` },
  });
  if (!resp.ok) {
    const text = await resp.text();
    throw new Error(`HTTP ${resp.status}: ${text}`);
  }
  return resp.json();
}

function parseFirestoreValue(value) {
  if (!value) return null;
  if ('stringValue' in value) return value.stringValue;
  if ('integerValue' in value) return parseInt(value.integerValue);
  if ('doubleValue' in value) return value.doubleValue;
  if ('booleanValue' in value) return value.booleanValue;
  if ('nullValue' in value) return null;
  if ('timestampValue' in value) return value.timestampValue;
  if ('arrayValue' in value) {
    return (value.arrayValue.values || []).map(parseFirestoreValue);
  }
  if ('mapValue' in value) {
    const result = {};
    for (const [k, v] of Object.entries(value.mapValue.fields || {})) {
      result[k] = parseFirestoreValue(v);
    }
    return result;
  }
  if ('geoPointValue' in value) return value.geoPointValue;
  if ('referenceValue' in value) return value.referenceValue;
  if ('bytesValue' in value) return value.bytesValue;
  return value;
}

function parseDocument(doc) {
  const fields = doc.fields || {};
  const result = {};
  for (const [key, value] of Object.entries(fields)) {
    result[key] = parseFirestoreValue(value);
  }
  return result;
}

async function listCollectionIds(token, parentPath) {
  const url = `${BASE_URL}${parentPath}:listCollectionIds`;
  try {
    const resp = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({}),
    });
    if (!resp.ok) return [];
    const data = await resp.json();
    return data.collectionIds || [];
  } catch {
    return [];
  }
}

async function exportCollection(token, collectionPath, depth = 0) {
  const indent = '  '.repeat(depth + 1);
  let allDocs = [];
  let nextPageToken = null;

  do {
    let url = `${BASE_URL}/${collectionPath}?pageSize=300`;
    if (nextPageToken) url += `&pageToken=${nextPageToken}`;
    
    const data = await fetchWithToken(url, token);
    const docs = data.documents || [];
    allDocs = allDocs.concat(docs);
    nextPageToken = data.nextPageToken || null;
  } while (nextPageToken);

  const result = {};

  for (const doc of allDocs) {
    const docId = doc.name.split('/').pop();
    const parsed = parseDocument(doc);

    // Check subcollections
    const docPath = doc.name.replace(`projects/${PROJECT_ID}/databases/(default)/documents/`, '');
    const subCollIds = await listCollectionIds(token, `/${docPath}`);

    if (subCollIds.length > 0) {
      const subs = {};
      for (const subId of subCollIds) {
        console.log(`${indent}📂 ${docId}/${subId}...`);
        subs[subId] = await exportCollection(token, `${docPath}/${subId}`, depth + 1);
      }
      parsed._subcollections = subs;
    }

    result[docId] = parsed;
  }

  return result;
}

async function main() {
  // Get access token via Google OAuth using Firebase CLI refresh token
  const configPaths = [
    path.join(process.env.USERPROFILE || '', '.config', 'configstore', 'firebase-tools.json'),
    path.join(process.env.APPDATA || '', 'configstore', 'firebase-tools.json'),
    path.join(process.env.APPDATA || '', 'firebase', 'config.json'),
  ];

  let refreshToken = null;
  for (const p of configPaths) {
    try {
      if (fs.existsSync(p)) {
        const raw = JSON.parse(fs.readFileSync(p, 'utf-8'));
        refreshToken = raw?.tokens?.refresh_token || raw?.user?.tokens?.refresh_token;
        if (refreshToken) {
          console.log(`🔑 Found credentials in ${path.basename(p)}`);
          break;
        }
      }
    } catch {}
  }

  if (!refreshToken) {
    console.error('❌ No Firebase refresh token found. Run: npx firebase login');
    process.exit(1);
  }

  // Exchange refresh token for access token using Google OAuth
  console.log('🔄 Exchanging token...');
  const tokenResp = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
      client_id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
      client_secret: 'j9iVZfS8kkCEFUPaAeJV0sAi',
    }),
  });

  if (!tokenResp.ok) {
    const err = await tokenResp.text();
    console.error('❌ Token exchange failed:', err);
    process.exit(1);
  }

  const { access_token } = await tokenResp.json();
  console.log('✅ Authenticated!\n');

  // List root collections
  console.log('🔍 Listing root collections...');
  const rootCollections = await listCollectionIds(access_token, '');
  console.log(`   Found: ${rootCollections.join(', ') || '(none)'}\n`);

  const fullExport = {};

  for (const colId of rootCollections) {
    console.log(`📦 Exporting: ${colId}...`);
    fullExport[colId] = await exportCollection(access_token, colId);
    const count = Object.keys(fullExport[colId]).length;
    console.log(`   ✅ ${count} document(s)\n`);
  }

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const outputFile = path.join(__dirname, `db_snapshot_${timestamp}.json`);
  fs.writeFileSync(outputFile, JSON.stringify(fullExport, null, 2), 'utf-8');

  console.log(`\n✅ Database exported to: ${outputFile}`);
  console.log(`   Size: ${(fs.statSync(outputFile).size / 1024).toFixed(1)} KB`);
}

main().catch((err) => {
  console.error('❌ Export failed:', err.message || err);
  process.exit(1);
});
