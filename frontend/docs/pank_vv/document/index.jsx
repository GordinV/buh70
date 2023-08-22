'use strict';
const React = require('react');
const PropTypes = require('prop-types');

const DocumentTemplate = require('./../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    InputDate = require('../../../components/input-date/input-date.jsx'),
    SelectData = require('../../../components/select-data/select-data.jsx'),
    InputNumber = require('../../../components/input-number/input-number.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    ButtonEdit = require('../../../components/button-register/button-register-edit/button-register-edit.jsx'),
    ButtonSearch = require('../../../components/button-register/button-register-filter/button-register-filter.jsx'),
    Loading = require('./../../../components/loading/index.jsx');

const styles = require('./styles');

/**
 * Класс реализует документ справочника признаков.
 */
class Tunnus extends React.PureComponent {
    constructor(props) {
        super(props);

        this.state = {
            docId: props.docId ? props.docId : Number(props.match.params.docId),
            loadedData: false,
            isShowSearch: false
        };
        this.renderer = this.renderer.bind(this);
        this.btnEditMKClick = this.btnEditMKClick.bind(this);
        this.searchSuccess = this.searchSuccess.bind(this);
        this.btnSearchClick = this.btnSearchClick.bind(this);
    }

    render() {
        return (
            <DocumentTemplate docId={this.state.docId}
                              ref='document'
                              docTypeId='PANK_VV'
                              module={this.props.module}
                              initData={this.props.initData}
                              userData={this.props.userData}
                              renderer={this.renderer}
                              focusElement={'input-kood'}
                              history={this.props.history}
                              reload={true}

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
            // не загружены данные
            return (<div style={styles.doc}>
                <Loading label={'Laadimine...'}/>
            </div>);
        }
        return (
            <div style={styles.doc}>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputText title="Pank ID "
                                   name='pank_id'
                                   ref="input-pank_id"
                                   readOnly={!self.state.edited}
                                   value={self.docData.pank_id || ''}
                                   onChange={self.handleInputChange}/>
                    </div>
                </div>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputDate title='Maksepäev:'
                                   name='valid'
                                   value={self.docData.kpv}
                                   ref='input-kpv'
                                   readOnly={!self.state.edited}
                                   onChange={self.handleInputChange}/>
                    </div>
                </div>

                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputNumber title='Summa: '
                                     name='summa'
                                     value={Number(self.docData.summa)}
                                     ref='summa'
                                     readOnly={!self.state.edited}
                                     onChange={self.handleInputChange}/>
                    </div>
                </div>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputText title="Viitenumber:"
                                   name='viitenumber'
                                   ref="input-viitenumber"
                                   readOnly={!self.state.edited}
                                   value={self.docData.viitenumber || ''}
                                   onChange={self.handleInputChange}/>
                    </div>
                    <div style={styles.docColumn}>
                        <label>
                            {`(${self.docData.nimi ? self.docData.nimi || ',' || self.docData.asutus : 'Puudub'})`}
                        </label>
                    </div>
                </div>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputText title="Reg.(Isiku) kood:"
                                   name='isikukood'
                                   ref="input-isikukood"
                                   readOnly={!self.state.edited}
                                   value={self.docData.isikukood || ''}
                                   onChange={self.handleInputChange}/>
                    </div>
                </div>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputText title="Maksja:"
                                   name='maksja'
                                   ref="input-maksja"
                                   readOnly={!self.state.edited}
                                   value={self.docData.maksja || ''}
                                   onChange={self.handleInputChange}/>
                    </div>
                    <div style={styles.docColumn}>
                        {this.state.isShowSearch ?
                            (<SelectData title="Leia maksja:"
                                         name='maksja'
                                         libName="pank_vv"
                                         lisaParameter={true}
                                         history={this.props.history}
                                         sqlFields={['maksja', 'isikukood']}
                                         data={[]}
                                         value={self.docData.maksja || ''}
                                         defaultValue={self.docData.maksja}
                                         boundToGrid='maksja'
                                         boundToData='maksja'
                                         ref="select-maksja"
                                         btnDelete={false}
                                         onChange={this.searchSuccess}
                                         readOnly={false}/>) :
                            <ButtonSearch
                                style={styles.ButtonSearch}
                                onClick={this.btnSearchClick}
                            />}
                    </div>
                </div>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputText title="Maksja AA:"
                                   name='iban'
                                   ref="input-iban"
                                   readOnly={!self.state.edited}
                                   value={self.docData.iban || ''}
                                   onChange={self.handleInputChange}/>
                    </div>
                </div>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputText title="Pank:"
                                   name='pank'
                                   ref="input-pank"
                                   readOnly={!self.state.edited}
                                   value={self.docData.pank || ''}
                                   onChange={self.handleInputChange}/>

                    </div>
                </div>
                <div style={styles.docRow}>
                    <TextArea title="Selgitus"
                              name='selg'
                              ref="textarea-selg"
                              onChange={self.handleInputChange}
                              value={self.docData.selg || ''}
                              readOnly={!self.state.edited}/>
                </div>
                {self.docData.doc_id ?
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <InputText title="Koostatud MK:"
                                       name='number'
                                       ref="input-number"
                                       readOnly={true}
                                       value={self.docData.number || ''}
                                       onChange={self.handleInputChange}/>
                        </div>
                        <div style={styles.docColumn}>
                            <ButtonEdit
                                ref='btnEdit'
                                value={'Muuda'}
                                onClick={this.btnEditMKClick}
                                show={!self.state.edited}
                                style={styles.btnEdit}
                                disabled={false}
                            />
                        </div>
                    </div> : null}

            </div>
        );
    }

    // обработчик события клиска на кнопке редактирования контр-агента
    btnEditMKClick() {
        let docMkId = this.refs['document'].docData.doc_id;

        // осуществит переход на карточку контр-агента
        this.props.history.push(`/lapsed/smk/${docMkId}`);
    }

    /**
     * при успешном результате поиска, скопируем результат
     */
    searchSuccess() {
        let docData = this.refs['document'].docData;
        let obj = this.refs['document']['refs']['select-maksja'];
        let result;
        if (obj && obj.state) {
            let activeRow = obj.state.gridActiveRow;
            result = obj.state.gridData[activeRow];
        }

        if (result && result.vn_s && !docData.viitenumber) {
            // получили результат. копируем ВН
            docData.viitenumber = result.vn_s;
            docData.nimi = result.nimi;
        }
        this.setState({isShowSearch: !this.state.isShowSearch});
//        this.forceUpdate()

    }

    btnSearchClick() {
        this.setState({isShowSearch: !this.state.isShowSearch});
    }


}

Tunnus.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object
};

Tunnus.defaultProps = {
    initData: {},
};


module.exports = (Tunnus);
