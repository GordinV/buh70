'use strict';

const fs = require('fs');
const path = require('path');
const {
    xmlToJson,
    convertInvoice,
    convertInvoiceItem,
    classifyCostObjective,
    extractBpm
} = require('../routes/ai/e-arved/xml_to_json');

describe('xml_to_json unit tests', () => {
    test('classifyCostObjective correctly identifies code dimensions', () => {
        expect(classifyCostObjective('01112')).toBe('kood1'); // Tegevusala (5 digits)
        expect(classifyCostObjective('LE-P')).toBe('kood2');  // Allikas (source)
        expect(classifyCostObjective('5500')).toBe('kood5');  // Eelarve artikkel (4 digits)
        expect(classifyCostObjective('800599')).toBe('tp');   // Tehingupartner (6 digits)
        expect(classifyCostObjective('')).toBe(null);
    });

    test('convertInvoiceItem maps fields and classifies accounting entries', () => {
        const itemEntry = {
            Description: 'Test Product',
            ItemAmount: '2',
            ItemPrice: '50',
            ItemSum: '100',
            ItemTotal: '124',
            VAT: {
                VATRate: '24',
                VATSum: '24'
            },
            ItemReserve: [
                { extensionId: 'eakOppositeAccount', InformationContent: '201000' }
            ],
            Accounting: {
                JournalEntry: [
                    { GeneralLedger: '550002', CostObjective: '5500' },
                    { GeneralLedger: '550002', CostObjective: '01112' },
                    { GeneralLedger: '550002', CostObjective: 'LE-P' },
                    { GeneralLedger: '550002', CostObjective: '800599' }
                ]
            }
        };

        const result = convertInvoiceItem(itemEntry, { nomid: 17748 });
        expect(result.nimetus).toBe('Test Product');
        expect(result.kogus).toBe(2);
        expect(result.hind).toBe(50);
        expect(result.kbmta).toBe(100);
        expect(result.km).toBe('24');
        expect(result.kbm).toBe(24);
        expect(result.summa).toBe(124);
        expect(result.konto).toBe('550002');
        expect(result.kood1).toBe('01112');
        expect(result.kood2).toBe('LE-P');
        expect(result.kood5).toBe('5500');
        expect(result.tp).toBe('800599');
        expect(result.korr_konto).toBeUndefined();
        expect(result.nomid).toBe(17748);
    });

    test('convertInvoice sets asutusid to seller RegNumber and extracts bpm confirmators', () => {
        const mockInvoice = {
            regNumber: '75008427',
            InvoiceParties: {
                SellerParty: {
                    RegNumber: '10127606'
                },
                BuyerParty: {
                    RegNumber: '75008427'
                }
            },
            InvoiceInformation: {
                InvoiceNumber: '48095',
                InvoiceDate: '2026-09-02',
                DueDate: '2026-09-12',
                Extension: [
                    {
                        extensionId: 'eakConfirmationCreator',
                        InformationContent: '48612183747|Anastassia Moldon'
                    },
                    {
                        extensionId: 'eakConfirmation',
                        InformationName: '2019-04-02 08:39:48',
                        InformationContent: '47608105226|Jelena Golubeva|VERIFIED|'
                    }
                ]
            },
            PaymentInfo: {
                PayToAccount: 'EE281010562005465000'
            },
            InvoiceSumGroup: {
                InvoiceSum: '96',
                TotalSum: '119.04',
                VAT: {
                    VATSum: '23.04'
                }
            },
            InvoiceItem: []
        };

        const result = convertInvoice(mockInvoice);
        expect(result.id).toBe(0);
        expect(result.data.asutusid).toBe(10127606);
        expect(result.data.aa).toBe('EE281010562005465000');
        expect(result.data.number).toBe('48095');
        expect(result.data.kpv).toBe('20260902');
        expect(result.data.tahtaeg).toBe('20260912');
        expect(result.data.kbmta).toBe(96);
        expect(result.data.kbm).toBe(23.04);
        expect(result.data.summa).toBe(119.04);
        expect(result.data.rekv_regkood).toBe('75008427');
        expect(Array.isArray(result.data.bpm)).toBe(true);
        expect(result.data.bpm).toEqual([
            { isik: 'Anastassia Moldon', kpv: '2026-09-02', rolli: 'creator' },
            { isik: 'Jelena Golubeva', kpv: '2019-04-02 08:39:48', rolli: 'VERIFIED' }
        ]);
    });

    test('extractBpm extracts and deduplicates confirmators correctly', () => {
        const invoice = {
            InvoiceInformation: {
                InvoiceDate: '2019-04-01',
                Extension: [
                    {
                        extensionId: 'eakConfirmationCreator',
                        InformationContent: '48612183747|Anastassia Moldon'
                    },
                    {
                        extensionId: 'eakConfirmCreator',
                        InformationContent: '48612183747|Anastassia Moldon'
                    },
                    {
                        extensionId: 'eakConfirmation',
                        InformationName: '2019-04-02 08:39:48',
                        InformationContent: '47608105226|Jelena Golubeva|VERIFIED|'
                    },
                    {
                        extensionId: 'eakConfirmation',
                        InformationName: '2019-04-03 09:11:38',
                        InformationContent: '46610172217|Jelena Tõekanina|VERIFIED|'
                    }
                ]
            }
        };

        const bpm = extractBpm(invoice);
        expect(bpm).toEqual([
            { isik: 'Anastassia Moldon', kpv: '2019-04-01', rolli: 'creator' },
            { isik: 'Jelena Golubeva', kpv: '2019-04-02 08:39:48', rolli: 'VERIFIED' },
            { isik: 'Jelena Tõekanina', kpv: '2019-04-03 09:11:38', rolli: 'VERIFIED' }
        ]);
    });

    test('extractBpm handles standard ConfirmationList tags', () => {
        const invoice = {
            InvoiceInformation: {
                InvoiceDate: '2026-01-15'
            },
            ConfirmationList: {
                Confirmation: [
                    {
                        isik: 'Ivan Ivanov',
                        kpv: '2026-01-16 10:00:00',
                        rolli: 'kinnitaja'
                    }
                ]
            }
        };

        const bpm = extractBpm(invoice);
        expect(bpm).toEqual([
            { isik: 'Ivan Ivanov', kpv: '2026-01-16 10:00:00', rolli: 'kinnitaja' }
        ]);
    });

    test('xmlToJson parses XML file fixture and produces expected e_arved.json format', async () => {
        const xmlPath = path.join(__dirname, 'fixtures/sample_e_arved.xml');
        const jsonPath = path.join(__dirname, '../routes/ai/e-arved/e_arved.json');

        const result = await xmlToJson(xmlPath, { outputFile: jsonPath });
        expect(Array.isArray(result)).toBe(true);
        expect(result.length).toBe(2);

        // Первый счет (ARGO ELECTRONICS OÜ)
        expect(result[0].data.asutusid).toBe(10127606);
        expect(result[0].data.number).toBe('48095');
        expect(result[0].data.kpv).toBe('20260902');
        expect(result[0].data.summa).toBe(119.04);
        expect(result[0].data.korr_konto).toBe('201000');
        expect(result[0].data.gridData.length).toBe(2);
        expect(result[0].data.gridData[0].korr_konto).toBeUndefined();
        expect(result[0].data.gridData[1].korr_konto).toBeUndefined();

        // Второй счет (Telia Eesti AS)
        expect(result[1].data.asutusid).toBe(10234957);
        expect(result[1].data.number).toBe('20260849296993');
        expect(result[1].data.kpv).toBe('20260831');
        expect(result[1].data.summa).toBe(29.51);
        expect(result[1].data.korr_konto).toBe('201000');
        expect(result[1].data.gridData.length).toBe(1);
        expect(result[1].data.gridData[0].hind).toBe(23.8);
        expect(result[1].data.gridData[0].kogus).toBe(1);
        expect(result[1].data.gridData[0].korr_konto).toBeUndefined();
    });

    test('xmlToJson accepts raw XML string directly on input and returns JSON array', async () => {
        const rawXml = fs.readFileSync(path.join(__dirname, 'fixtures/sample_e_arved.xml'), 'utf8');

        // Вызов с передачей XML строки
        const result = await xmlToJson(rawXml);
        expect(Array.isArray(result)).toBe(true);
        expect(result.length).toBe(2);
        expect(result[0].data.asutusid).toBe(10127606);
        expect(result[0].data.korr_konto).toBe('201000');
    });

    test('xml_to_json function can be required directly and handles empty input gracefully', async () => {
        const xml_to_json = require('../routes/ai/e-arved/xml_to_json');
        expect(typeof xml_to_json).toBe('function');

        const emptyResult = await xml_to_json('');
        expect(emptyResult).toEqual([]);

        const nullResult = await xml_to_json(null);
        expect(nullResult).toEqual([]);
    });
});
