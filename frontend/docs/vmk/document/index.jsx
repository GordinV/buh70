'use strict';

const React = require('react');
const PropTypes = require('prop-types');

const DocumentTemplate = require('../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    InputDate = require('../../../components/input-date/input-date.jsx'),
    InputNumber = require('../../../components/input-number/input-number.jsx'),
    Select = require('../../../components/select/select.jsx'),
    SelectData = require('../../../components/select-data/select-data.jsx'),
    ButtonEdit = require('../../../components/button-register/button-register-edit/button-register-edit.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    DataGrid = require('../../../components/data-grid/data-grid.jsx'),
    DokProp = require('../../../components/docprop/docprop.jsx'),
    relatedDocuments = require('../../../mixin/relatedDocuments.jsx'),
    ModalPage = require('./../../../components/modalpage/modalPage.jsx'),
    styles = require('./vmk-style');

const LIBRARIES = [
    {id: 'kontod', filter: ``},
    {id: 'dokProps', filter: `where kood = 'VMK'`},
    {id: 'users', filter: ''},
    {id: 'tunnus', filter: ''},
    {id: 'project', filter: ''},
    {id: 'artikkel', filter: ''},
    {id: 'allikas', filter: ''},
    {id: 'tegev', filter: ''},
    {id: 'aa', filter: ''},
    {id: 'asutused', filter: `where id in (select asutusid from lapsed.vanemad)`},
    {id: 'vanem', filter: ``},
    {id: 'nomenclature', filter: `where dok in ('VMK','MK')`}
];

class Vmk extends React.Component {
    constructor(props) {
        super(props);

        this.state = {
            docId: props.docId ? props.docId : Number(props.match.params.docId),
            loadedData: false,
            module: this.props.module

        };

        this.createGridRow = this.createGridRow.bind(this);
        this.recalcDocSumma = this.recalcDocSumma.bind(this);
        this.recalcRowSumm = this.recalcRowSumm.bind(this);

        this.renderer = this.renderer.bind(this);
        this.gridValidateFields = this.gridValidateFields.bind(this);

        this.pages = [{pageName: 'Väljamakse korraldus', docTypeId: 'SMK'}];
    }


    render() {
        return <DocumentTemplate docId={this.state.docId}
                                 ref='document'
                                 docTypeId='VMK'
                                 module={'lapsed'}
                                 reload={true}
                                 history={this.props.history}
                                 initData={this.props.initData}
                                 libs={LIBRARIES}
                                 pages={this.pages}
                                 renderer={this.renderer}
                                 createGridRow={this.createGridRow}
                                 gridValidator={this.gridValidateFields}
                                 recalcDoc={this.recalcDocSumma}
                                 focusElement={'input-number'}
        />

    }

    /**
     * Вернет кастомные компоненты документа
     * @returns {XML}
     */
    renderer(self) {
        let isEditeMode = self.state.edited;
        if (!self.docData) {
            return
        }

        // формируем зависимости
        if (self.docData.relations) {
            relatedDocuments(self);
        }

        return (
            <div>
                <div className='div-doc'>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <InputText title='Number'
                                       name='number'
                                       value={String(self.docData.number) || ''}
                                       ref="input-number"
                                       onChange={self.handleInputChange}
                                       readOnly={!isEditeMode}/>
                            <InputDate title='Kuupäev '
                                       name='kpv'
                                       value={self.docData.kpv}
                                       ref='input-kpv'
                                       onChange={self.handleInputChange}
                                       readOnly={!isEditeMode}/>
                            <Select title="Arveldus arve"
                                    name='aaid'
                                    libs="aa"
                                    value={Number(self.docData.aa_id) || 0}
                                    data={self.libs['aa']}
                                    defaultValue={String(self.docData.pank) || self.libs['aa']}
                                    collId={'id'}
                                    onChange={self.handleInputChange}
                                    ref="select-aaId"
                                    readOnly={!isEditeMode}/>
                            <InputText title="Arve nr."
                                       name='arvnr'
                                       value={self.docData.arvnr || ''}
                                       ref="input-arvnr"
                                       onChange={self.handleInputChange}
                                       readOnly={true}/>
                            <InputDate title='Maksepäev '
                                       name='maksepaev'
                                       value={self.docData.maksepaev}
                                       ref='input-maksepaev'
                                       onChange={self.handleInputChange}
                                       readOnly={!isEditeMode}/>
                            <InputText title='Viitenumber '
                                       name='viitenr'
                                       value={self.docData.viitenr || ''}
                                       ref='input-viitenr'
                                       onChange={self.handleInputChange}
                                       readOnly={!isEditeMode}/>
                        </div>
                        <div style={styles.docColumn}>
                            <DokProp title="Konteerimine: "
                                     name='doklausid'
                                     data={self.libs['dokProps']}
                                     dokTypeId={'VMK'}
                                     value={Number(self.docData.doklausid) || 0}
                                     defaultValue={self.docData.dokprop || ''}
                                     history={this.props.history}
                                     ref="dokprop"
                                     onChange={self.handleInputChange}
                                     readOnly={!isEditeMode}/>
                        </div>
                    </div>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <SelectData title="Lapse nimi:"
                                        name='lapsid'
                                        libName="laps"
                                        sqlFields={['nimi', 'isikukood']}
                                        data={[]}
                                        value={self.docData.lapsid || 0}
                                        defaultValue={self.docData.lapse_nimi}
                                        boundToGrid='nimi'
                                        boundToData='nimi'
                                        ref="select-lapsid"
                                        btnDelete={false}
                                        userData={self.userData}
                                        onChange={self.handleInputChange}
                                        readOnly={!isEditeMode}/>
                        </div>
                        <div style={styles.docColumn}>
                            <ButtonEdit
                                ref='btnEdit'
                                value={'Muuda'}
                                onClick={this.btnEditLapsClick}
                                show={!isEditeMode}
                                style={styles.btnEdit}
                                disabled={false}
                            />
                        </div>
                    </div>
                </div>
                < div
                    style={styles.docRow}>
                    < TextArea
                        title="Selgitus"
                        name='selg'
                        ref="textarea-selg"
                        value={self.docData.selg || ''}
                        onChange={self.handleInputChange}
                        readOnly={
                            !isEditeMode
                        }
                    />
                </div>

                <div style={styles.docRow}>
                    <DataGrid source='details'
                              gridData={self.docData.gridData}
                              gridColumns={self.docData.gridConfig}
                              showToolBar={isEditeMode}
                              handleGridRow={self.handleGridRow}
                              handleGridBtnClick={self.handleGridBtnClick}
                              readOnly={!isEditeMode}
                              style={styles.grid.headerTable}
                              ref="data-grid"/>
                </div>
                <div style={styles.docRow}>
                    <InputText title="Kokku: "
                               name='summa'
                               ref="input-summa"
                               value={String(self.docData.summa) || '0.00'}
                               width='auto'
                               disabled={true}/>
                </div>
                <div style={styles.docRow}>
                    <TextArea title="Märkused"
                              name='muud'
                              ref="textarea-muud"
                              value={self.docData.muud || ''}
                              onChange={self.handleInputChange}
                              readOnly={!isEditeMode}/>
                </div>

                {self.state.gridRowEdit ?
                    this.createGridRow(self)
                    : null}

            </div>
        );
    }

    /**
     * формирует объекты модального окна редактирования строки грида
     * @returns {XML}
     */
    createGridRow(self) {
        let row = self.gridRowData ? self.gridRowData : {},
            validateMessage = '', // self.state.warning
            buttonOkReadOnly = validateMessage.length > 0 || !self.state.checked,
            modalObjects = ['btnOk', 'btnCancel'];

        if (buttonOkReadOnly) {
            // уберем кнопку Ок
            modalObjects.splice(0, 1);
        }

        if (!row) return <div/>;

        const nomData = self.libs['nomenclature'].filter(row => {
            if (row.dok === 'MK' || row.dok === 'VMK') {
                return row;
            }
        });

        // наложить фильтр на список плательщиков, если указан витенумбер
        let data = self.libs['asutused'];
        if (self.docData.viitenr && self.libs['vanem'] && self.libs['vanem'].length && self.libs['asutused'] && self.libs['asutused'].length) {

            // найти родителя
            let vanem = self.libs['vanem'].filter(row => row.viitenr === self.docData.viitenr);

            if (vanem && vanem.length) {
                // нашли родителя, ставим фильтр
                data = data.filter(row => !!vanem.find(kiri => kiri.id === row.id));
            }
        }


        return (<div className='.modalPage'>
                <ModalPage
                    modalObjects={modalObjects}
                    ref="modalpage-grid-row"
                    show={true}
                    modalPageBtnClick={self.modalPageClick}
                    modalPageName='Rea lisamine / parandamine'>
                    <div ref="grid-row-container">
                        <div style={styles.docRow}>
                            <Select title="Operatsioon"
                                    name='nomid'
                                    data={nomData}
                                    value={row.nomid || 0}
                                    collId='id'
                                    defaultValue={row.kood || ''}
                                    ref='nomid'
                                    onChange={self.handleGridRowChange}/>
                        </div>
                        <div style={styles.docRow}>
                            <Select title="Partner"
                                    name='asutusid'
                                    data={self.libs['asutused']}
                                    value={row.asutusid}
                                    defaultValue={row.asutus || ''}
                                    collId='id'
                                    ref='asutusid'
                                    onChange={self.handleGridRowChange}/>
                        </div>
                        <div style={styles.docRow}>
                            <InputText title='Arveldus arve: '
                                       name='aa'
                                       value={row.aa || ''}
                                       bindData={false}
                                       ref='aa'
                                       readOnly={false}
                                       onChange={self.handleGridRowInput}/>
                        </div>
                        <div style={styles.docRow}>
                            <InputNumber title='Summa: '
                                         name='summa'
                                         value={Number(row.summa)}
                                         bindData={false}
                                         ref='summa'
                                         onChange={self.handleGridRowInput}/>
                        </div>
                        <div style={styles.docRow}>
                            <Select title="Korr. konto"
                                    name='konto'
                                    libs="kontod"
                                    data={self.libs['kontod']}
                                    value={row.konto}
                                    ref='konto'
                                    collId="kood"
                                    onChange={self.handleGridRowChange}/>
                        </div>
                        <div style={styles.docRow}>
                            <Select title="Tunnus:"
                                    name='tunnus'
                                    libs="tunnus"
                                    data={self.libs['tunnus']}
                                    value={row.tunnus}
                                    ref='tunnus'
                                    collId="kood"
                                    onChange={self.handleGridRowChange}/>
                        </div>
                        <div style={styles.docRow}>
                            <Select title="Project:"
                                    name='proj'
                                    libs="project"
                                    data={self.libs['project']}
                                    value={row.proj}
                                    ref='project'
                                    collId="kood"
                                    onChange={self.handleGridRowChange}/>
                        </div>
                    </div>
                    <div><span>{validateMessage}</span></div>
                </ModalPage>
            </
                div>
        )
            ;
    }

    /**
     * перерасчет итоговой суммы документа
     */
    recalcDocSumma() {
        let doc = this.refs['document'];
        doc.docData['summa'] = 0;
        doc.docData.gridData.forEach(row => {
            doc.docData['summa'] += Number(row['summa']);
        });
    }

    /**
     * подставит код операции
     */
    recalcRowSumm() {
        let doc = this.refs['document'];

        if (!Object.keys(doc.gridRowData).length) {
            return;
        }

        //подставим наименование услогу

        if (doc.gridRowData['nomid']) {
            let nomDataName = doc.libs['nomenclature'].find(lib => lib.id === Number(doc.gridRowData['nomid']));

            if (nomDataName) {
                doc.gridRowData['kood'] = nomDataName.kood;
                doc.gridRowData['nimetus'] = nomDataName.nimetus;
            }
        }

        //подставим наименование
        if (doc.gridRowData['asutusid']) {

            let asutusDataName = doc.libs['asutused'].find(lib => lib.id === Number(doc.gridRowData['asutusid']));

            if (asutusDataName) {
                doc.gridRowData['asutus'] = asutusDataName.nimetus;
                doc.gridRowData['aa'] = asutusDataName.pank;
            }

        }
    }


    /**
     * валидатор для строки грида
     * @returns {string}
     */
    gridValidateFields() {
        let warning = '';
        let doc = this.refs['document'];
        if (doc && doc.gridRowData) {

            // только после проверки формы на валидность
            if (doc.gridRowData && !doc.gridRowData['nomid']) warning = warning + ' Код операции';
            if (!doc.gridRowData['summa']) warning = warning + ' Сумма';
            if (!doc.gridRowData['asutusid']) warning = warning + ' Платильщик';

            this.recalcRowSumm();
            this.recalcDocSumma('summa');

        }
        return warning;

    }

}

Vmk.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object,
    userData: PropTypes.object,
};

Vmk.defaultProps = {
    initData: {},
    userData: {}
};

module.exports = (Vmk);