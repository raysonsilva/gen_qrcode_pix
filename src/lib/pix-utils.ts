/**
 * PIX Static QR Code Generator Utility
 * Based on "Manual de Padrões para Iniciação do Pix v2.9.0"
 */

export interface PixData {
  key: string;
  receiverName: string;
  receiverCity: string;
  amount?: string;
  description?: string;
  txid?: string;
}

function crc16(data: string): string {
  let crc = 0xFFFF;
  const polynomial = 0x1021;

  for (let i = 0; i < data.length; i++) {
    let b = data.charCodeAt(i);
    for (let j = 0; j < 8; j++) {
      let bit = ((b >> (7 - j)) & 1) === 1;
      let c15 = ((crc >> 15) & 1) === 1;
      crc <<= 1;
      if (c15 !== bit) crc ^= polynomial;
    }
  }

  crc &= 0xFFFF;
  return crc.toString(16).toUpperCase().padStart(4, '0');
}

function formatField(id: string, value: string): string {
  const length = value.length.toString().padStart(2, '0');
  return `${id}${length}${value}`;
}

export function generatePixPayload(data: PixData): string {
  const parts: string[] = [];

  // 00: Payload Format Indicator
  parts.push(formatField('00', '01'));

  // 26: Merchant Account Information
  const gui = formatField('00', 'br.gov.bcb.pix');
  const key = formatField('01', data.key);
  const description = data.description ? formatField('02', data.description) : '';
  parts.push(formatField('26', `${gui}${key}${description}`));

  // 52: Merchant Category Code
  parts.push(formatField('52', '0000'));

  // 53: Transaction Currency (986 = BRL)
  parts.push(formatField('53', '986'));

  // 54: Transaction Amount
  if (data.amount && parseFloat(data.amount) > 0) {
    parts.push(formatField('54', parseFloat(data.amount).toFixed(2)));
  }

  // 58: Country Code
  parts.push(formatField('58', 'BR'));

  // 59: Merchant Name
  // Remove accents and limit to 25 chars for safety, though manual says up to 99 for the whole block
  const cleanName = data.receiverName.normalize("NFD").replace(/[\u0300-\u036f]/g, "").substring(0, 25);
  parts.push(formatField('59', cleanName));

  // 60: Merchant City
  const cleanCity = data.receiverCity.normalize("NFD").replace(/[\u0300-\u036f]/g, "").substring(0, 15);
  parts.push(formatField('60', cleanCity));

  // 62: Additional Data Field Template
  const txid = data.txid ? data.txid.substring(0, 25) : '***';
  parts.push(formatField('62', formatField('05', txid)));

  // 63: CRC16
  const payloadWithoutCrc = parts.join('') + '6304';
  const crc = crc16(payloadWithoutCrc);
  
  return `${payloadWithoutCrc}${crc}`;
}
