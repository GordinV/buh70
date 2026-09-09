'use strict';

const path = require('path');
const fs = require('fs');
const {
    getXMLFile,
    buildSoapEnvelope,
    parseResponseMeta,
    formatCurrentDate,
    mergeXmlResponses
} = require('../routes/ai/e-arved/getXMLFile');

describe('getXMLFile unit tests', () => {
    test('formatCurrentDate returns string in YYYY-MM-DD 00:00:00 format', () => {
        const testDate = new Date(2026, 8, 4, 15, 30, 0); // 2026-09-04
        const formatted = formatCurrentDate(testDate);
        expect(formatted).toBe('2026-09-04 00:00:00');
    });

    test('formatCurrentDate works with date strings and various formats', () => {
        expect(formatCurrentDate('2026-05-10')).toBe('2026-05-10 00:00:00');
        expect(formatCurrentDate('20260908')).toBe('2026-09-08 00:00:00');
        expect(formatCurrentDate(20260908)).toBe('2026-09-08 00:00:00');
        expect(formatCurrentDate('06.09.2026')).toBe('2026-09-06 00:00:00');
        expect(formatCurrentDate('6.9.2026')).toBe('2026-09-06 00:00:00');
        expect(formatCurrentDate('06/09/2026')).toBe('2026-09-06 00:00:00');
        expect(formatCurrentDate('06.09.2026 14:30:00')).toBe('2026-09-06 14:30:00');
    });

    test('buildSoapEnvelope builds valid SOAP XML request with params', () => {
        const xml = buildSoapEnvelope({
            since: '2026-09-01 00:00:00',
            authPhrase: 'test-auth-phrase',
            state: 'VERIFIED'
        });

        expect(xml).toContain('<soapenv:Envelope');
        expect(xml).toContain('since="2026-09-01 00:00:00"');
        expect(xml).toContain('authPhrase="test-auth-phrase"');
        expect(xml).toContain('<erp:state>VERIFIED</erp:state>');
    });

    test('buildSoapEnvelope supports DD.MM.YYYY and YYYYMMDD formats in since', () => {
        const xml1 = buildSoapEnvelope({
            since: '06.09.2026',
            authPhrase: 'test-auth-phrase'
        });
        expect(xml1).toContain('since="2026-09-06 00:00:00"');

        const xml2 = buildSoapEnvelope({
            since: '20260908',
            authPhrase: 'test-auth-phrase'
        });
        expect(xml2).toContain('since="2026-09-08 00:00:00"');
    });

    test('parseResponseMeta parses includesLatest="YES" and latestChange', () => {
        const sampleXml = '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">' +
            '<SOAP-ENV:Body>' +
            '<BuyInvoiceExportResponse xmlns="http://e-arvetekeskus.eu/erp" includesLatest="YES" latestChange="2026-09-03 11:24:04">' +
            '<E_Invoice><Header><Date>2026-09-04</Date></Header></E_Invoice>' +
            '</BuyInvoiceExportResponse>' +
            '</SOAP-ENV:Body></SOAP-ENV:Envelope>';

        const meta = parseResponseMeta(sampleXml);
        expect(meta.isFault).toBe(false);
        expect(meta.includesLatest).toBe('YES');
        expect(meta.latestChange).toBe('2026-09-03 11:24:04');
    });

    test('parseResponseMeta parses SOAP Fault and error codes', () => {
        const faultXml = '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">' +
            '<SOAP-ENV:Body>' +
            '<SOAP-ENV:Fault>' +
            '<faultcode xmlns:ns0="http://e-arvetekeskus.eu/erp">ns0:93</faultcode>' +
            '<faultstring xml:lang="en">Request rate too high</faultstring>' +
            '</SOAP-ENV:Fault>' +
            '</SOAP-ENV:Body></SOAP-ENV:Envelope>';

        const meta = parseResponseMeta(faultXml);
        expect(meta.isFault).toBe(true);
        expect(meta.faultCode).toBe('ns0:93');
        expect(meta.faultString).toBe('Request rate too high');
    });

    test('mergeXmlResponses merges multiple invoices and updates count', () => {
        const xml1 = '<SOAP-ENV:Envelope><SOAP-ENV:Body><BuyInvoiceExportResponse><E_Invoice>' +
            '<Header><TotalNumberInvoices>1</TotalNumberInvoices></Header>' +
            '<Invoice invoiceId="1"><InvoiceNumber>INV-1</InvoiceNumber></Invoice>' +
            '</E_Invoice></BuyInvoiceExportResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>';

        const xml2 = '<SOAP-ENV:Envelope><SOAP-ENV:Body><BuyInvoiceExportResponse><E_Invoice>' +
            '<Header><TotalNumberInvoices>1</TotalNumberInvoices></Header>' +
            '<Invoice invoiceId="2"><InvoiceNumber>INV-2</InvoiceNumber></Invoice>' +
            '</E_Invoice></BuyInvoiceExportResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>';

        const merged = mergeXmlResponses([xml1, xml2]);
        expect(merged).toContain('<TotalNumberInvoices>2</TotalNumberInvoices>');
        expect(merged).toContain('invoiceId="1"');
        expect(merged).toContain('invoiceId="2"');
    });

    test('buildSoapEnvelope supports custom authPhrase and since date', () => {
        const customAuth = '99999:customhashstring';
        const customSince = '2026-09-07 10:00:00';
        const xml = buildSoapEnvelope({
            since: customSince,
            authPhrase: customAuth
        });
        expect(xml).toContain('authPhrase="99999:customhashstring"');
        expect(xml).toContain('since="2026-09-07 10:00:00"');
    });
});
