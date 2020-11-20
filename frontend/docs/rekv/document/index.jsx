'use strict';
const React = require('react');
const PropTypes = require('prop-types');

const DocumentTemplate = require('./../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    DataGrid = require('../../../components/data-grid/data-grid.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    ModalPage = require('../../../components/modalpage/modalPage.jsx'),
    Select = require('../../../components/select/select.jsx'),
    CheckBox = require('../../../components/input-checkbox/input-checkbox.jsx'),

    styles = require('./styles');

const LIB_OBJS = require('./../../../../config/constants').REKV.LIB_OBJS;


/**
 * Класс реализует документ справочника признаков.
 */
class Rekv extends React.PureComponent {
    constructor(props) {
        super(props);

        this.state = {
            docId: props.docId ? props.docId : Number(props.match.params.docId),
            loadedData: false
        };
        this.renderer = this.renderer.bind(this);
        this.createGridRow = this.createGridRow.bind(this);
    }

    render() {
        return (
            <DocumentTemplate docId={this.state.docId}
                              ref='document'
                              docTypeId='REKV'
                              history={this.props.history}
                              module={this.props.module}
                              libs={LIB_OBJS}
                              initData={this.props.initData}
                              renderer={this.renderer}
                              createGridRow={this.createGridRow}

            />
        )
    }

    /**
     * Метод вернет кастомный компонент
     * @param self
     * @returns {*}
     */
    renderer(self) {
        if (!self.docData) {
            return null;
        }
        const gridData = self.docData.gridData,
            gridColumns = self.docData.gridConfig;

        return (
            <div style={styles.doc}>
                <div style={styles.docRow}>
                    <InputText title="Regkood: "
                               name='regkood'
                               ref="input-regkood"
                               readOnly={!self.state.edited}
                               value={self.docData.regkood || ''}
                               onChange={self.handleInputChange}/>
                </div>
                <div style={styles.docRow}>
                    <InputText title="KBM kood: "
                               name='kbmkood'
                               ref="input-kbmkood"
                               readOnly={!self.state.edited}
                               value={self.docData.kbmkood || ''}
                               onChange={self.handleInputChange}/>
                </div>
                < div style={styles.docRow}>
                    < InputText
                        title="Nimetus: "
                        name='nimetus'
                        ref="input-nimetus"
                        readOnly={!self.state.edited}
                        value={self.docData.nimetus || ''}
                        onChange={self.handleInputChange}/>
                </div>
                <div style={styles.docRow}>
                    <InputText title="Täis. nimetus: "
                               name='muud'
                               ref="input-muud"
                               readOnly={!self.state.edited}
                               value={self.docData.muud || ''}
                               onChange={self.handleInputChange}/>
                </div>
                <div style={styles.docRow}>
                    <Select title="Asutuse liik:"
                            name='liik'
                            data={self.libs['asutuse_liik']}
                            value={self.docData.liik || ''}
                            defaultValue={self.docData.liik || ''}
                            ref='liik'
                            collId="kood"
                            readOnly={!self.state.edited}
                            onChange={self.handleInputChange}/>


                </div>

                <div style={styles.docRow}>
                    <TextArea title="Aadress: "
                              name='aadress'
                              ref="textarea-aadress"
                              onChange={self.handleInputChange}
                              value={self.docData.aadress || ''}
                              readOnly={!self.state.edited}/>
                </div>
                <div style={styles.docRow}>
                    <InputText title="Juhataja: "
                               name='juht'
                               ref="input-juht"
                               readOnly={!self.state.edited}
                               value={self.docData.juht || ''}
                               onChange={self.handleInputChange}/>
                </div>
                <div style={styles.docRow}>

                    <InputText title="Raamatupidaja: "
                               name='raama'
                               ref="input-raama"
                               readOnly={!self.state.edited}
                               value={self.docData.raama || ''}
                               onChange={self.handleInputChange}/>
                </div>
                <div style={styles.docRow}>

                    <InputText title="Email: "
                               name='email'
                               ref="input-email"
                               readOnly={!self.state.edited}
                               value={self.docData.email || ''}
                               onChange={self.handleInputChange}/>
                </div>
                <div style={styles.docRow}>
                    <InputText title="Omniva salasõna: "
                               name='earved'
                               ref="input-earved"
                               readOnly={!self.state.edited}
                               value={self.docData.earved || ''}
                               onChange={self.handleInputChange}/>
                </div>
                <div style={styles.docRow}>
                    <InputText title="E-arve asutuse reg.kood: "
                               name='earve_regkood'
                               ref="input-earve_regkood"
                               readOnly={!self.state.edited}
                               value={self.docData.earve_regkood || ''}
                               onChange={self.handleInputChange}/>
                </div>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputText title="SEB e-arve aa: "
                                   name='seb_earve'
                                   ref="input-seb_earve"
                                   readOnly={!self.state.edited}
                                   value={self.docData.seb_earve || ''}
                                   onChange={self.handleInputChange}/>
                    </div>
                    <div style={styles.docColumn}>
                        <InputText title="SEB kasutaja tunnus: "
                                   name='seb'
                                   ref="input-seb_parool"
                                   readOnly={!self.state.edited}
                                   value={self.docData.seb || ''}
                                   onChange={self.handleInputChange}/>
                    </div>
                </div>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputText title="SWED e-arve aa: "
                                   name='swed_earve'
                                   ref="input-swed-earve"
                                   readOnly={!self.state.edited}
                                   value={self.docData.swed_earve || ''}
                                   onChange={self.handleInputChange}/>
                    </div>
                    <div style={styles.docColumn}>
                        <InputText title="SWED kasutaja tunnus: "
                                   name='swed'
                                   ref="input-swed_parool"
                                   readOnly={!self.state.edited}
                                   value={self.docData.swed || ''}
                                   onChange={self.handleInputChange}/>
                    </div>
                </div>
                <div style={styles.docRow}>
                    <DataGrid source='details'
                              gridData={gridData}
                              gridColumns={gridColumns}
                              showToolBar={self.state.edited}
                              handleGridRow={this.handleGridRow}
                              handleGridBtnClick={self.handleGridBtnClick}
                              readOnly={!self.state.edited}
                              style={styles.grid.headerTable}
                              ref="data-grid"/>
                </div>
                {self.state.gridRowEdit ?
                    this.createGridRow(self)
                    : null}


            </div>);
    }

    /**
     * Создаст компонет строки грида
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

        return (<div className='.modalPage'>
            <ModalPage
                modalObjects={modalObjects}
                ref="modalpage-grid-row"
                show={true}
                modalPageBtnClick={self.modalPageClick}
                modalPageName='Rea lisamine / parandamine'>
                <div ref="grid-row-container">
                    {self.state.gridWarning.length ? (
                        <div style={styles.docRow}>
                            <span>{self.state.gridWarning}</span>
                        </div>
                    ) : null}

                    <div style={styles.docRow}>
                        <InputText title='Number: '
                                   name='arve'
                                   value={row.arve || ''}
                                   readOnly={false}
                                   disabled={false}
                                   bindData={false}
                                   ref='number'
                                   onChange={self.handleGridRowInput}/>
                    </div>
                    <div style={styles.docRow}>
                        <InputText title='Nimetus: '
                                   name='nimetus'
                                   value={row.nimetus || ''}
                                   readOnly={false}
                                   disabled={false}
                                   bindData={false}
                                   ref='number'
                                   onChange={self.handleGridRowInput}/>
                    </div>
                    <div style={styles.docRow}>
                        <Select title="Tüüp: "
                                name='kassapank'
                                data={[{id: 0, nimetus: 'Kassa'}, {id: 1, nimetus: 'Pank'}, {id: 2, nimetus: 'TP'}]}
                                value={row.kassapank || ''}
                                ref='kassapank'
                                collId="id"
                                onChange={self.handleGridRowChange}/>
                    </div>
                    <div style={styles.docRow}>
                        <Select title="Konto: "
                                name='konto'
                                data={self.libs['kontod']}
                                value={row.konto || ''}
                                ref='konto'
                                collId="kood"
                                onChange={self.handleGridRowChange}/>
                    </div>
                    <div style={styles.docRow}>
                        <CheckBox title="Kas põhiline?"
                                  name='default_'
                                  value={Boolean(self.docData.default_)}
                                  ref={'checkbox_default_'}
                                  onChange={self.handleInputChange}
                                  readOnly={false}
                        />
                    </div>

                </div>
                <div><span>{validateMessage}</span></div>
            </ModalPage>
        </div>);
    }


}

Rekv.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object
};

Rekv.defaultProps = {
    initData: {},
};


module.exports = (Rekv);
