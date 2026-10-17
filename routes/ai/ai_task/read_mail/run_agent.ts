import * as dotenv from 'dotenv';
import * as fs from 'fs';
import * as path from 'path';

// Загружаем .env
function findEnvFile(): string | undefined {
  let dir = __dirname;
  while (dir !== path.dirname(dir)) {
    const candidate = path.join(dir, '.env');
    if (fs.existsSync(candidate)) return candidate;
    dir = path.dirname(dir);
  }
  return undefined;
}

const envPath = findEnvFile();
if (envPath) {
  dotenv.config({ path: envPath });
} else {
  dotenv.config();
}

import { runReadMailSubagent } from './agent';

const SAMPLE_BOUNCE_EMAIL_1 = `From: Õppetasu [mailto:kallekaleva@kallekaleva.planet.ee]
Sent: Monday, October 12, 2026 2:18 PM
To: Andrei Vargunin <andrei.vargunin@narva.ee>
Subject: Fwd: Fwd: Permanent failure notice
-------- Edastatud kiri --------
Teema:
Fwd: Permanent failure notice
Kuupäev:
Mon, 12 Oct 2026 08:30:31 +0300
Saatja:
Õppetasu [<oppetasu@narva.ee>](mailto:oppetasu@narva.ee)
Vastamise aadress:
[oppetasu@narva.ee](mailto:oppetasu@narva.ee)
Organisatsioon:
Narva Linnavalitsuse Kultuuriosakonna raamatupidamisteenistus
Saaja:
Karina Portnova [<karina.portnova@narvakultuur.ee>](mailto:karina.portnova@narvakultuur.ee)
Teema:
Saadan dokument nr. 101-10772, 1010177139
Saatja:
Õppetasu [<oppetasu@narva.ee>](mailto:oppetasu@narva.ee)
Kuupäev:
08.10.2026, 17:30
Saaja:
[jekaterinabazutova@gmail.ru](mailto:jekaterinabazutova@gmail.ru)
-------- Edastatud kiri --------
Teema:
Permanent failure notice
Kuupäev:
Sat, 10 Oct 2026 21:49:14 +0300
Saatja:
[MAILER-DAEMON@narva.ee](mailto:MAILER-DAEMON@narva.ee)
Saaja:
[oppetasu@narva.ee](mailto:oppetasu@narva.ee)
I am deeply sorry, but I was not able to deliver your mail to the following addresses:
[jekaterinabazutova@gmail.ru](mailto:jekaterinabazutova@gmail.ru) : Domain lookup error
This is a permanent delivery failure. The delivery has been tried 20 times and will not be rescheduled again.`;

const SAMPLE_BOUNCE_EMAIL_2 = `From: Õppetasu [mailto:kallekaleva@kallekaleva.planet.ee]
Sent: Monday, October 12, 2026 2:18 PM
To: Andrei Vargunin <andrei.vargunin@narva.ee>
Subject: Fwd: Fwd: Permanent failure notice
-------- Edastatud kiri --------
Teema:
Fwd: Permanent failure notice
Kuupäev:
Mon, 12 Oct 2026 08:29:50 +0300
Saatja:
Õppetasu [<oppetasu@narva.ee>](mailto:oppetasu@narva.ee)
Vastamise aadress:
[oppetasu@narva.ee](mailto:oppetasu@narva.ee)
Organisatsioon:
Narva Linnavalitsuse Kultuuriosakonna raamatupidamisteenistus
Saaja:
Jelena Verestsagina [<jelena.verestsagina@narva.ee>](mailto:jelena.verestsagina@narva.ee)
Teema:
Saadan dokument nr. 100-11324, 1000164479
Saatja:
Õppetasu [<oppetasu@narva.ee>](mailto:oppetasu@narva.ee)
Kuupäev:
08.10.2026, 14:00
Saaja:
[gkucheruk@gmail.com](mailto:gkucheruk@gmail.com)
-------- Edastatud kiri --------
Teema:
Permanent failure notice
Kuupäev:
Sat, 10 Oct 2026 18:19:19 +0300
Saatja:
[MAILER-DAEMON@narva.ee](mailto:MAILER-DAEMON@narva.ee)
Saaja:
[oppetasu@narva.ee](mailto:oppetasu@narva.ee)
I am deeply sorry, but I was not able to deliver your mail to the following addresses:
[gkucheruk@gmail.com](mailto:gkucheruk@gmail.com) : 4.2.2 The recipient's inbox is out of storage space. Please direct the 4.2.2 recipient to 4.2.2 https://support.google.com/mail/?p=OverQuotaTemp 2adb3069b0e04-5bcddec2f0bsi4074070e87.95 - gsmtp
This is a permanent delivery failure. The delivery has been tried 20 times and will not be rescheduled again.`;

const SAMPLE_BOUNCE_EMAIL_3 = `From: Õppetasu [mailto:kallekaleva@kallekaleva.planet.ee]
Sent: Monday, October 12, 2026 2:19 PM
To: Andrei Vargunin <andrei.vargunin@narva.ee>
Subject: Fwd: Fwd: Permanent failure notice
-------- Edastatud kiri --------
Teema:
Fwd: Permanent failure notice
Kuupäev:
Thu, 8 Oct 2026 08:15:56 +0300
Saatja:
Õppetasu [<oppetasu@narva.ee>](mailto:oppetasu@narva.ee)
Vastamise aadress:
[oppetasu@narva.ee](mailto:oppetasu@narva.ee)
Organisatsioon:
Narva Linnavalitsuse Kultuuriosakonna raamatupidamisteenistus
Saaja:
Maksim Grigorjev [<maksim.grigorjev@narva.ee>](mailto:maksim.grigorjev@narva.ee)
Teema:
Saadan dokument nr. 098-10566, 0980169799
Saatja:
Õppetasu [<oppetasu@narva.ee>](mailto:oppetasu@narva.ee)
Kuupäev:
08.10.2026, 08:00
Saaja:
[tleera651@gmail.com](mailto:tleera651@gmail.com)
-------- Edastatud kiri --------
Teema:
Permanent failure notice
Kuupäev:
Thu, 8 Oct 2026 08:01:01 +0300
Saatja:
[MAILER-DAEMON@narva.ee](mailto:MAILER-DAEMON@narva.ee)
Saaja:
[oppetasu@narva.ee](mailto:oppetasu@narva.ee)
I am deeply sorry, but I was not able to deliver your mail to the following addresses:
[tleera651@gmail.com](mailto:tleera651@gmail.com) : 5.1.1 The email account that you tried to reach does not exist. Please try 5.1.1 double-checking the recipient's email address for typos or 5.1.1 unnecessary spaces. For more information, go to 5.1.1 https://support.google.com/mail/?p=NoSuchUser 2adb3069b0e04-5bcd30a8a52si1587306e87.186 - gsmtp
This is a permanent delivery failure. The delivery has been tried 0 times and will not be rescheduled again.`;

async function main() {
  const isDemo3 = process.argv.includes('--sample=3') || process.argv.includes('--demo=3');
  const isDemo2 = process.argv.includes('--sample=2') || process.argv.includes('--demo=2');
  const isDemo = process.argv.some(arg => arg.startsWith('--demo') || arg.startsWith('--sample'));

  const sampleNum = isDemo3 ? 3 : isDemo2 ? 2 : 1;

  console.log('===================================================');
  console.log('              ЗАПУСК АГЕНТА READ_MAIL              ');
  console.log('===================================================');
  console.log('Режим:', isDemo ? `Тестовый (демонстрация на примере письма №${sampleNum})` : 'Боевой (получение писем с сервера IMAP)');
  console.log('IMAP Сервер:', process.env.IMAP_HOST || 'mail.narva.ee');
  console.log('IMAP Порт:', process.env.IMAP_PORT || '993');
  console.log('IMAP Пользователь:', process.env.IMAP_USER || 'oppetasu');
  console.log('IMAP Пароль задан:', Boolean(process.env.IMAP_PASS));
  console.log('Начальная дата выборки:', '01.10.2026');
  console.log('---------------------------------------------------');

  try {
    let emailContent: string | undefined;
    if (isDemo) {
      if (isDemo3) emailContent = SAMPLE_BOUNCE_EMAIL_3;
      else if (isDemo2) emailContent = SAMPLE_BOUNCE_EMAIL_2;
      else emailContent = SAMPLE_BOUNCE_EMAIL_1;
    }

    const input = isDemo
      ? {
          emailContent,
          stateFilePath: path.resolve(__dirname, 'demo_read_mail_state.json'),
        }
      : {};

    const result = await runReadMailSubagent(input);

    console.log('---------------------------------------------------');
    console.log('=== ИТОГОВЫЙ РЕЗУЛЬТАТ РАБОТЫ АГЕНТА ===');
    console.log(`Найдено ошибок доставки: ${result.length}`);
    console.log(JSON.stringify(result, null, 2));
    console.log('===================================================');
  } catch (err: any) {
    console.error('Ошибка при выполнении агента:', err.message || err);
  }
}

main();
