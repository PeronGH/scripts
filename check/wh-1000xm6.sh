curl -s "https://info.update.sony.net/HP002/MDRID298402/info/info.xml" | \
node -e "
const crypto = require('crypto');
const chunks = [];
process.stdin.on('data', c => chunks.push(c));
process.stdin.on('end', () => {
  const data = Buffer.concat(chunks);
  const headerEnd = data.indexOf('\n\n');
  const header = data.slice(0, headerEnd).toString();
  const match = header.match(/eaid:(.*)/);
  const eaid = match[1];
  const encrypted = data.slice(headerEnd + 2);
  
  let result;
  if (eaid === 'ENC0003') {
    const key = Buffer.from('4fa27999ffd08b1fe4d260d57b6d3c17', 'hex');
    const decipher = crypto.createDecipheriv('aes-128-ecb', key, '');
    decipher.setAutoPadding(false);
    result = Buffer.concat([decipher.update(encrypted), decipher.final()]);
  } else {
    result = encrypted;
  }
  console.log(result.toString().replace(/\0+$/, ''));
});
"
