import os
import io
import json
import zipfile
import re
from urllib.parse import urlparse

import functions_framework
from flask import Response, request
from lxml import etree
from google.cloud import storage
import google.generativeai as genai
import vertexai

# --- Конфигурация Gemini API / Vertex AI ---
PROJECT_ID = os.environ.get("GOOGLE_CLOUD_PROJECT", "project-76db5b4b-6de8-4e1f-b88")
LOCATION = os.environ.get("GOOGLE_CLOUD_LOCATION", "us-central1")

vertexai.init(project=PROJECT_ID, location=LOCATION)

try:
    model = genai.GenerativeModel(
        "gemini-3.7-flash",
        generation_config={"temperature": 0.1}
    )
except Exception as e:
    print(f"Failed to initialize Gemini model via Vertex AI: {e}")
    raise RuntimeError(f"Failed to initialize Gemini model: {e}")

# --- Константы по умолчанию ---
DEFAULT_TSD_ZIP_URI = "gs://check_xml_bucket/xsd/tsd_schemas_2026.zip"

# --- Кэширование XSD схем ---
cached_xsd_schemas = {}

# --- Инициализация клиента Google Cloud Storage ---
storage_client = None

def get_storage_client():
    """Ленивая инициализация клиента Google Cloud Storage."""
    global storage_client
    if storage_client is None:
        print("Инициализация Google Cloud Storage API...")
        storage_client = storage.Client()
    return storage_client

def load_tsd_schema_bundle(env_uri_key="XSD_TSD_2026"):
    """
    Загружает многофайловый архив схем XBRL GL для TSD 2026 из GCS:
    gs://check_xml_bucket/xsd/tsd_schemas_2026.zip
    Распаковывает его в /tmp/xsd_tsd и загружает master_tsd_2026.xsd.
    """
    local_dir = "/tmp/xsd_tsd"
    local_master_xsd = os.path.join(local_dir, "master_tsd_2026.xsd")

    # Если уже распаковано в инстансе Cloud Run
    if os.path.exists(local_master_xsd):
        schema_doc = etree.parse(local_master_xsd)
        return etree.XMLSchema(schema_doc), "Cached TSD 2026 Master Schema"

    # Получаем URI из переменной окружения или берем дефолтный gs://check_xml_bucket/...
    xsd_uri = os.environ.get(env_uri_key, DEFAULT_TSD_ZIP_URI)

    try:
        parsed_uri = urlparse(xsd_uri)
        bucket_name = parsed_uri.netloc
        blob_name = parsed_uri.path.lstrip('/')
    except Exception as e:
        raise ValueError(f"Server config error: Failed to parse GCS URI for TSD: {e}")

    try:
        client = get_storage_client()
        bucket = client.bucket(bucket_name)
        blob = bucket.blob(blob_name)

        if not blob.exists():
            raise FileNotFoundError(f"TSD schema archive '{blob_name}' not found in bucket '{bucket_name}'.")

        print(f"Downloading TSD schemas from gs://{bucket_name}/{blob_name}...")
        zip_bytes = blob.download_as_bytes()

        os.makedirs(local_dir, exist_ok=True)
        with zipfile.ZipFile(io.BytesIO(zip_bytes)) as z:
            z.extractall(local_dir)
        print(f"TSD schemas extracted to {local_dir}")

        if not os.path.exists(local_master_xsd):
            raise FileNotFoundError(f"master_tsd_2026.xsd not found inside {blob_name}")

        schema_doc = etree.parse(local_master_xsd)
        xsd_schema = etree.XMLSchema(schema_doc)
        return xsd_schema, f"Loaded from gs://{bucket_name}/{blob_name}"

    except Exception as e:
        raise RuntimeError(f"Failed to load TSD schemas from Cloud Storage: {e}")

def load_xsd_schema(xsd_type_key):
    """
    Загружает XSD-схему из Google Cloud Storage и кэширует ее.
    Возвращает кортеж (etree.XMLSchema, xsd_text).
    """
    global cached_xsd_schemas

    xsd_type_key_upper = xsd_type_key.upper()

    if xsd_type_key_upper in cached_xsd_schemas:
        print(f"XSD schema for '{xsd_type_key_upper}' loaded from memory cache.")
        return cached_xsd_schemas[xsd_type_key_upper]

    # --- TSD 2026 (APA-TSD / XBRL GL) ---
    if xsd_type_key_upper in ('TSD', 'TSD_2026', 'APATSD', 'APA_TSD'):
        xsd_schema, xsd_text = load_tsd_schema_bundle()
        cached_xsd_schemas[xsd_type_key_upper] = (xsd_schema, xsd_text)
        return xsd_schema, xsd_text

    # --- SEPA ISO (Банковские платежи) ---
    elif xsd_type_key_upper == 'MK':
        env_xsd_uri = "XSD_SEPA_ISO"
        xsd_uri = os.environ.get(env_xsd_uri)
        if not xsd_uri:
            raise ValueError(f"Server config error: Environment variable '{env_xsd_uri}' is missing.")
        
        try:
            parsed_uri = urlparse(xsd_uri)
            bucket_name = parsed_uri.netloc
            xsd_blob_name = parsed_uri.path.lstrip('/')
        except Exception as e:
            raise ValueError(f"Server config error: Failed to parse GCS URI in '{env_xsd_uri}': {e}")
    else:
        # Старая оригинальная логика для остальных XSD-схем
        env_bucket_name = "XSD_BUCKET_NAME"
        env_blob_name = f"XSD_BLOB_NAME_{xsd_type_key_upper}"

        bucket_name = os.environ.get(env_bucket_name)
        xsd_blob_name = os.environ.get(env_blob_name)

        if not bucket_name or not xsd_blob_name:
            raise ValueError(f"Server config error: Environment variables '{env_bucket_name}' or '{env_blob_name}' are missing.")

    try:
        client = get_storage_client()
        bucket = client.bucket(bucket_name)
        blob = bucket.blob(xsd_blob_name)

        if not blob.exists():
            raise FileNotFoundError(f"XSD file '{xsd_blob_name}' not found in bucket '{bucket_name}'.")

        xsd_bytes = blob.download_as_bytes()
        xsd_schema = etree.XMLSchema(etree.fromstring(xsd_bytes))
        xsd_text = xsd_bytes.decode('utf-8')

        cached_xsd_schemas[xsd_type_key_upper] = (xsd_schema, xsd_text)
        print(f"XSD schema for '{xsd_type_key_upper}' loaded from gs://{bucket_name}/{xsd_blob_name} and cached.")
        return xsd_schema, xsd_text
    except Exception as e:
        raise RuntimeError(f"Failed to load XSD for '{xsd_type_key_upper}' from Cloud Storage: {e}")

# --- Кастомная функция для валидации эстонских имен ---
ALLOWED_NAME_PATTERN = re.compile(r"^[a-zA-ZÄäÖöÜüÕõŠšŽž0-9 \-.,&'\"]+$")

def validate_estonian_names(xml_tree):
    custom_errors = []
    name_elements = xml_tree.xpath('//*[contains(local-name(), "Nimi")]')
    for el in name_elements:
        if el.text and el.text.strip():
            name_value = el.text.strip()
            if not ALLOWED_NAME_PATTERN.match(name_value):
                custom_errors.append(f"Invalid characters in name: '{name_value}' (Tag: {el.tag}). Only Latin and Estonian letters allowed.")
    return custom_errors

# --- Специализированные бизнес-правила MTA для TSD 2026 ---
def validate_tsd_business_rules(xml_tree):
    errors = []
    warnings = []
    summary = {
        "regkood": None,
        "period": None,
        "transactions_count": 0,
        "refunds_count": 0,
        "total_amount": 0.0,
        "taxes": {}
    }

    # Регистрационный код
    reg_el = xml_tree.xpath('//*[local-name()="identifier"]')
    if reg_el and reg_el[0].text:
        summary["regkood"] = reg_el[0].text.strip()

    # Период
    start_kpv_el = xml_tree.xpath('//*[local-name()="periodCoveredStart"]')
    end_kpv_el = xml_tree.xpath('//*[local-name()="periodCoveredEnd"]')
    if start_kpv_el and end_kpv_el and start_kpv_el[0].text and end_kpv_el[0].text:
        start_kpv = start_kpv_el[0].text.strip()
        end_kpv = end_kpv_el[0].text.strip()
        summary["period"] = f"{start_kpv} .. {end_kpv}"
        if start_kpv[:7] != end_kpv[:7]:
            errors.append(f"TSD aruandeperiood peab olema ühe kalendrikuu piires ({start_kpv} vs {end_kpv})")
    else:
        errors.append("Puudub periood: periodCoveredStart või periodCoveredEnd")

    # Секции (entryHeader)
    headers = xml_tree.xpath('//*[local-name()="entryHeader"]')
    if not headers:
        errors.append("Vähemalt üks gl-cor:entryHeader peab olema määratud")

    valid_tax_codes = {'TSD_SM', 'TSD_KP', 'TSD_TK', 'TSD_TTK', 'TSD_KTM'}

    for h in headers:
        entry_num_el = h.xpath('./*[local-name()="entryNumber"]')
        entry_num = entry_num_el[0].text.strip() if (entry_num_el and entry_num_el[0].text) else ""
        if not entry_num.startswith("EE020100"):
            errors.append(f"Vigane entryNumber: '{entry_num}' (peab algama EE020100)")

        details = h.xpath('./*[local-name()="entryDetail"]')
        for d in details:
            summary["transactions_count"] += 1
            line_no_el = d.xpath('./*[local-name()="lineNumber"]')
            line_no = line_no_el[0].text.strip() if (line_no_el and line_no_el[0].text) else f"Tehing_{summary['transactions_count']}"

            # Проверка личного кода
            id_code_el = d.xpath('.//*[local-name()="identifierCode"]')
            if id_code_el and id_code_el[0].text:
                id_code = id_code_el[0].text.strip()
                if not re.match(r"^(EE)?\d{11}$", id_code):
                    warnings.append(f"{line_no}: Isikukood '{id_code}' ei vasta tavapärasele Eesti isikukoodile")

            # Проверка accountSub типов
            sub_types = [el.text.strip() for el in d.xpath('.//*[local-name()="accountSubType"]') if el.text]
            if "VALJAMLIIK2023ap" not in sub_types:
                errors.append(f"{line_no}: puudub accountSub VALJAMLIIK2023ap (väljamakse liik)")
            if "TOIMINGUTYYP2023ap" not in sub_types:
                errors.append(f"{line_no}: puudub accountSub TOIMINGUTYYP2023ap (toimingu tüüp 'R')")

            # Сумма выплаты
            amount_el = d.xpath('./*[local-name()="amount"]')
            amount_val = 0.0
            if amount_el and amount_el[0].text:
                try:
                    amount_val = float(amount_el[0].text.strip())
                    summary["total_amount"] += amount_val
                except ValueError:
                    errors.append(f"{line_no}: vigane summa '{amount_el[0].text.strip()}'")

            # Проверка событий (TSD01, TSD02) и показателей возвратов
            has_tsd02 = False
            tsd02_date = ""
            has_smvmsk = False
            for m in d.xpath('./*[local-name()="measurable"]'):
                mid = get_local_text(m, "measurableID")
                mdesc = get_local_text(m, "measurableDescription")
                mstart = get_local_text(m, "measurableStartDateTime")
                if mid == "TSD02":
                    has_tsd02 = True
                    tsd02_date = mstart
                if mdesc == "TSD_SMVMSK":
                    has_smvmsk = True

            if has_tsd02:
                summary["refunds_count"] += 1
                if entry_num == "EE0201003":
                    errors.append(f"{line_no}: KR_YLD_32 Sektsioonis EE0201003 ei tohi tagasimakse tunnus (TSD02) olla määratud")
                if not tsd02_date:
                    errors.append(f"{line_no}: KR_YLD_14 Tagasimakse (TSD02) korral peab algse väljamakse kuupäev olema määratud")
                if amount_val > 0:
                    errors.append(f"{line_no}: KR_YLD_24 Tagasimakse (TSD02) korral peab summa olema negatiivne või 0 ({amount_val})")
            else:
                if entry_num != "EE0201003" and amount_val < 0:
                    errors.append(f"{line_no}: KR_YLD_30 Tavalise väljamakse (ilma TSD02) korral peab summa olema positiivne või 0 ({amount_val})")
                if has_smvmsk:
                    errors.append(f"{line_no}: KR_SM_13 TSD_SMVMSK on lubatud ainult tagasimakse (TSD02) korral")

            # Проверка налогов
            taxes = d.xpath('./*[local-name()="taxes"]')
            for t in taxes:
                child_tags = [etree.QName(c).localname for c in t.iterchildren() if isinstance(c.tag, str)]
                if len(child_tags) >= 2 and child_tags[0] == "taxCode" and child_tags[1] == "taxAmount":
                    errors.append(f"{line_no}: XSD järjekorra viga elemendis <taxes>: <taxAmount> peab olema enne <taxCode>")

                tax_code_el = t.xpath('./*[local-name()="taxCode"]')
                tax_amt_el = t.xpath('./*[local-name()="taxAmount"]')
                tax_code = tax_code_el[0].text.strip() if (tax_code_el and tax_code_el[0].text) else ""
                tax_amt = float(tax_amt_el[0].text.strip()) if (tax_amt_el and tax_amt_el[0].text) else 0.0

                if tax_code and tax_code not in valid_tax_codes:
                    errors.append(f"{line_no}: tundmatu maksukood '{tax_code}'")
                elif tax_code:
                    summary["taxes"][tax_code] = round(summary["taxes"].get(tax_code, 0.0) + tax_amt, 2)

    summary["total_amount"] = round(summary["total_amount"], 2)
    return errors, warnings, summary


def get_local_text(parent, tag_name, default=""):
    els = parent.xpath(f'./*[local-name()="{tag_name}"]')
    if els and els[0].text:
        return els[0].text.strip()
    return default


def format_xml_for_gemini(xml_doc, is_tsd_2026=False, tsd_summary=None):
    """
    Преобразует XML-документ в компактный табличный вид (CSV/TSV) + метаданные шапки
    перед отправкой в Gemini, чтобы избежать ошибки превышения лимита в 1 048 576 токенов
    на больших файлах (Вариант 2).
    """
    root_tag = etree.QName(xml_doc).localname.lower()

    # 1. TSD 2026 (APA-TSD / XBRL GL)
    if is_tsd_2026 or root_tag == 'xbrl':
        lines = []
        lines.append("=== FORMAT: TSD 2026 (XBRL GL / APA-TSD) COMPACT CSV REPRESENTATION ===")
        if tsd_summary:
            lines.append(f"SUMMARY CALCULATED BY PARSER: {tsd_summary}")

        first_detail = xml_doc.xpath('(//*[local-name()="entryDetail"])[1]')
        if first_detail:
            sample_xml = etree.tostring(first_detail[0], encoding='unicode', pretty_print=True)
            lines.append("\nSAMPLE XML ELEMENT (1st entryDetail):")
            lines.append(sample_xml.strip())

        lines.append("\nALL TRANSACTIONS TABLE (CSV format, delimiter ';'):")
        lines.append("entryNumber;lineNumber;isikukood;valjamliik;toiming;amount;docDate;eventCode;eventStart;SMVM;MVT_kood;MVT_summa;other_meas;TSD_SM;TSD_TK;TSD_TTK;TSD_KP;TSD_KTM")

        headers = xml_doc.xpath('//*[local-name()="entryHeader"]')
        for h in headers:
            entry_num = get_local_text(h, "entryNumber")
            details = h.xpath('./*[local-name()="entryDetail"]')
            for d in details:
                line_no = get_local_text(d, "lineNumber")
                amount = get_local_text(d, "amount")
                doc_date = get_local_text(d, "documentDate")

                ik_el = d.xpath('.//*[local-name()="identifierCode"]')
                ik = ik_el[0].text.strip() if (ik_el and ik_el[0].text) else ""

                valjamliik = ""
                toiming = ""
                for sub in d.xpath('.//*[local-name()="accountSub"]'):
                    st = get_local_text(sub, "accountSubType")
                    sid = get_local_text(sub, "accountSubID")
                    if st == "VALJAMLIIK2023ap":
                        valjamliik = sid
                    elif st == "TOIMINGUTYYP2023ap":
                        toiming = sid

                events = []
                smvm = ""
                mvt_kood = ""
                mvt_summa = ""
                other_meas = []
                for m in d.xpath('./*[local-name()="measurable"]'):
                    mid = get_local_text(m, "measurableID")
                    mstart = get_local_text(m, "measurableStartDateTime")
                    mdesc = get_local_text(m, "measurableDescription")
                    mqty = get_local_text(m, "measurableQuantity")
                    if mid:
                        events.append(f"{mid}:{mstart}")
                    elif mdesc == "TSD_SMVM":
                        smvm = mqty
                    elif mdesc.startswith("MVT_"):
                        mvt_kood = mdesc.replace("MVT_", "")
                        mvt_summa = mqty
                    elif mdesc:
                        other_meas.append(f"{mdesc}={mqty}")

                event_str = ",".join(events)

                tax_map = {"TSD_SM": "", "TSD_TK": "", "TSD_TTK": "", "TSD_KP": "", "TSD_KTM": ""}
                for t in d.xpath('./*[local-name()="taxes"]'):
                    tcode = get_local_text(t, "taxCode")
                    tamt = get_local_text(t, "taxAmount")
                    if tcode in tax_map:
                        tax_map[tcode] = tamt
                    elif tcode:
                        other_meas.append(f"{tcode}={tamt}")

                row = [
                    entry_num, line_no, ik, valjamliik, toiming, amount, doc_date,
                    event_str, "", smvm, mvt_kood, mvt_summa,
                    ",".join(other_meas),
                    tax_map["TSD_SM"], tax_map["TSD_TK"], tax_map["TSD_TTK"],
                    tax_map["TSD_KP"], tax_map["TSD_KTM"]
                ]
                lines.append(";".join(row))

        return "\n".join(lines)

    # 2. TSD Lisa 1a (tsd_vorm)
    if root_tag == 'tsd_vorm':
        lines = []
        lines.append("=== FORMAT: TSD LISA 1A (tsd_vorm) COMPACT CSV REPRESENTATION ===")
        header_fields = [
            "regKood", "vorm", "laadimisViis", "c108_Aasta", "c109_Kuu",
            "c110_Tm", "c115_Sm", "c116_Tk", "c117_Kp", "c118_KohustKokku"
        ]
        header_info = {f: get_local_text(xml_doc, f) for f in header_fields}
        lines.append(f"HEADER FIELDS: {header_info}")

        first_isik = xml_doc.xpath('(//*[local-name()="tsd_L1_A_Isik"])[1]')
        if first_isik:
            sample_xml = etree.tostring(first_isik[0], encoding='unicode', pretty_print=True)
            lines.append("\nSAMPLE XML ELEMENT (1st tsd_L1_A_Isik):")
            lines.append(sample_xml.strip())

        lines.append("\nALL PAYMENTS TABLE (CSV format, delimiter ';'):")
        lines.append("c1000_Kood;c1010_Nimi;c1020_ValiKood;c1030_Summa;c1060_Smvm;c1070_TvpVah;c1080_KuumVah;c1090_KuumSuur;c1100_Sm;c1110_Kp;c1120_Tkvm;c1130_Tk;c1140_Ttk;c1170_Tm;c1150_TuliKood;c1160_Summa")

        calc_totals = {"summa": 0.0, "sm": 0.0, "kp": 0.0, "tk": 0.0, "ttk": 0.0, "tm": 0.0, "rows": 0}

        for isik in xml_doc.xpath('//*[local-name()="tsd_L1_A_Isik"]'):
            kood = get_local_text(isik, "c1000_Kood")
            nimi = get_local_text(isik, "c1010_Nimi")
            for vm in isik.xpath('.//*[local-name()="tsd_L1_A_Vm"]'):
                calc_totals["rows"] += 1
                vali_kood = get_local_text(vm, "c1020_ValiKood")
                summa = get_local_text(vm, "c1030_Summa")
                smvm = get_local_text(vm, "c1060_Smvm")
                tvp_vah = get_local_text(vm, "c1070_TvpVah")
                kuum_vah = get_local_text(vm, "c1080_KuumVah")
                kuum_suur = get_local_text(vm, "c1090_KuumSuur")
                sm = get_local_text(vm, "c1100_Sm")
                kp = get_local_text(vm, "c1110_Kp")
                tkvm = get_local_text(vm, "c1120_Tkvm")
                tk = get_local_text(vm, "c1130_Tk")
                ttk = get_local_text(vm, "c1140_Ttk")
                tm = get_local_text(vm, "c1170_Tm")

                tuli_kood = ""
                mvt_summa = ""
                mvt_el = vm.xpath('.//*[local-name()="tsd_L1_A_Mvt"]')
                if mvt_el:
                    tuli_kood = get_local_text(mvt_el[0], "c1150_TuliKood")
                    mvt_summa = get_local_text(mvt_el[0], "c1160_Summa")

                for k, v in [("summa", summa), ("sm", sm), ("kp", kp), ("tk", tk), ("ttk", ttk), ("tm", tm)]:
                    try:
                        if v:
                            calc_totals[k] = round(calc_totals[k] + float(v), 2)
                    except ValueError:
                        pass

                row = [
                    kood, nimi, vali_kood, summa, smvm, tvp_vah, kuum_vah, kuum_suur,
                    sm, kp, tkvm, tk, ttk, tm, tuli_kood, mvt_summa
                ]
                lines.append(";".join(row))

        calc_totals["tk_plus_ttk"] = round(calc_totals["tk"] + calc_totals["ttk"], 2)
        calc_totals["kohust_kokku"] = round(calc_totals["tm"] + calc_totals["sm"] + calc_totals["tk_plus_ttk"] + calc_totals["kp"], 2)
        lines.insert(2, f"ROW TOTALS CALCULATED BY PARSER: {calc_totals}")
        return "\n".join(lines)

    # 3. Makseandmik
    if root_tag == 'makseandmik':
        lines = []
        lines.append("=== FORMAT: MAKSEANDMIK COMPACT CSV REPRESENTATION ===")
        lines.append(f"ROOT ATTRIBUTES: {dict(xml_doc.attrib)}")
        lines.append("MaksjaRegistrikood;SaajaRegistrikood;TP;SaajaNimi;MakseKp;Summa;KontoKlass;TA")
        for kirje in xml_doc.xpath('//*[local-name()="Kirje"]'):
            row = [
                get_local_text(kirje, "MaksjaRegistrikood"),
                get_local_text(kirje, "SaajaRegistrikood"),
                get_local_text(kirje, "TP"),
                get_local_text(kirje, "SaajaNimi"),
                get_local_text(kirje, "MakseKp"),
                get_local_text(kirje, "Summa"),
                get_local_text(kirje, "KontoKlass"),
                get_local_text(kirje, "TA")
            ]
            lines.append(";".join(row))
        return "\n".join(lines)

    # 4. Остальные XML-документы
    compact_xml = etree.tostring(xml_doc, encoding='unicode', pretty_print=False)
    if len(compact_xml) <= 200000:
        return etree.tostring(xml_doc, encoding='unicode', pretty_print=True)
    return compact_xml[:2000000]


def make_json_response(data, status_code=200):
    return Response(
        json.dumps(data, ensure_ascii=False),
        status=status_code,
        mimetype="application/json"
    )


@functions_framework.http
def validate_xml(request):
    """
    HTTP Cloud Function для валидации XML против XSD-схем (TSD 2026, MK, DEFAULT)
    """
    user_prompt = request.form.get('prompt', '').strip()
    type_of_xsd = request.form.get('type_of_XSD', '').strip().upper()

    if 'file' not in request.files:
        return make_json_response({"valid": False, "errors": ["No file provided in form-data. Key must be 'file'."]}, 400)

    xml_file = request.files['file']
    if xml_file.filename == '':
        return make_json_response({"valid": False, "errors": ["No selected file."]}, 400)

    xml_content = xml_file.read()
    
    # Удаление BOM и пробелов
    BOM_UTF8 = b'\xef\xbb\xbf'
    if xml_content.startswith(BOM_UTF8):
        xml_content = xml_content[len(BOM_UTF8):]
    xml_content = xml_content.strip()

    # Парсим XML документ
    try:
        xml_doc = etree.fromstring(xml_content)
    except Exception as e:
        return make_json_response({"valid": False, "errors": [f"Error parsing XML: {e}"]}, 400)

    # Автоопределение TSD 2026 по корневому тегу xbrl, если тип не указан явно
    root_tag = etree.QName(xml_doc).localname.lower()
    is_tsd_2026 = (type_of_xsd in ('TSD', 'TSD_2026', 'APATSD')) or (root_tag == 'xbrl')

    if not type_of_xsd:
        type_of_xsd = 'TSD_2026' if is_tsd_2026 else 'DEFAULT'

    try:
        xsd_schema, current_xsd_text = load_xsd_schema(type_of_xsd)
    except (ValueError, FileNotFoundError, RuntimeError) as e:
        return make_json_response({"valid": False, "errors": [str(e)]}, 500)

    all_validation_errors = []
    all_warnings = []
    tsd_summary = None

    # 1. Валидация по XSD
    try:
        xsd_schema.assertValid(xml_doc)
    except etree.DocumentInvalid as e:
        all_validation_errors.append(str(e))
        for err in xsd_schema.error_log:
            all_validation_errors.append(str(err))

    # 2. Бизнес-валидация для TSD 2026
    if is_tsd_2026:
        tsd_errs, tsd_warns, tsd_summary = validate_tsd_business_rules(xml_doc)
        all_validation_errors.extend(tsd_errs)
        all_warnings.extend(tsd_warns)

    # 3. Валидация эстонских имен
    custom_name_errors = validate_estonian_names(xml_doc)
    all_validation_errors.extend(custom_name_errors)

    xml_is_valid = not bool(all_validation_errors)

    if not xml_is_valid:
        resp = {"valid": False, "errors": all_validation_errors}
        if all_warnings:
            resp["warnings"] = all_warnings
        if tsd_summary:
            resp["summary"] = tsd_summary
        return make_json_response(resp, 400)

    # 4. Анализ через Gemini (если передан prompt)
    if user_prompt:
        formatted_data = format_xml_for_gemini(xml_doc, is_tsd_2026=is_tsd_2026, tsd_summary=tsd_summary)
        full_prompt = (
            f"You are a strict XML Data Quality Auditor for Estonian Tax and Banking declarations.\n"
            f"Note: To optimize token usage while preserving 100% of records, repeating XML structures "
            f"have been converted into a compact CSV table (delimiter ';') along with the document header, "
            f"calculated totals, and a sample XML element.\n"
            f"TASK: {user_prompt}\n\n"
            f"DATA:\n{formatted_data}"
        )
        try:
            response = model.generate_content(full_prompt)
            resp = {
                "valid": True,
                "errors": [],
                "gemini_analysis": response.text
            }
            if all_warnings:
                resp["warnings"] = all_warnings
            if tsd_summary:
                resp["summary"] = tsd_summary
            return make_json_response(resp, 200)
        except Exception as e:
            return make_json_response({"valid": False, "errors": [f"Failed to generate content with Gemini: {e}"]}, 500)

    resp = {"valid": True, "errors": [], "message": "XML is valid against the schema."}
    if all_warnings:
        resp["warnings"] = all_warnings
    if tsd_summary:
        resp["summary"] = tsd_summary
    return make_json_response(resp, 200)
