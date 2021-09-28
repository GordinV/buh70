'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const InputNumber = require('../../components/input-number/input-number.jsx');
const InputText = require('../../components/input-text/input-text.jsx');
const BtnGetXml = require('./../../components/button-register/button-task/index.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');

const styles = require('./styles');
const DocContext = require('./../../doc-context.js');
const DOC_TYPE_ID = 'KUUTABELI_ARUANNE';
const TOOLBAR_PROPS = {
    add: false,
    edit: false,
    delete: false,
    start: false,
    print: true,
    email: true
};


/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.renderer = this.renderer.bind(this);
        this.onClickHandler = this.onClickHandler.bind(this);

        this.state = {
            read: 0,
            filtri_read: 0,
            arvestatud: 0,
            soodustus: 0,
            summa: 0
        }

    }

    render() {
        return (
            <div>
                <DocumentRegister initData={this.props.initData}
                                  history={this.props.history ? this.props.history : null}
                                  module={this.props.module}
                                  ref='register'
                                  toolbarProps={TOOLBAR_PROPS}
                                  docTypeId={DOC_TYPE_ID}
                                  style={styles}
                                  render={this.renderer}/>
                <InputText title="Filtri all / read kokku:"
                           name='read_kokku'
                           style={styles.total}
                           ref="input-read"
                           value={String(this.state.filtri_read + '/' + this.state.read) || 0}
                           disabled={true}/>
                <InputNumber title="Arvestatud (sh ümberarvestus) kokku:"
                             name='arvestatud_kokku'
                             style={styles.total}
                             ref="input-arvestatud"
                             value={Number(this.state.arvestatud) || 0}
                             disabled={true}/>
                <InputNumber title="Soodustus kokku:"
                             name='soodustus_kokku'
                             style={styles.total}
                             ref="input-soodustus"
                             value={Number(this.state.soodustus) || 0}
                             disabled={true}/>
                <InputNumber title="Arvestatud ja Soodustus kokku:"
                             name='arv_ja_soodustus_kokku'
                             style={styles.total}
                             ref="input-arv_ja_soodustus"
                             value={Number(this.state.summa) || 0}
                             disabled={true}/>

            </div>
        )
    }

    renderer(self) {

        if (self.gridData) {
            let arvestatud = self.gridData && self.gridData.length && self.gridData[0].arvestatud_total ? self.gridData[0].arvestatud_total : 0;
            let soodustus = self.gridData && self.gridData.length && self.gridData[0].soodustus_total ? self.gridData[0].soodustus_total : 0;
            let summa = self.gridData && self.gridData.length && self.gridData[0].summa_total ? self.gridData[0].summa_total : 0;

            let filtri_read = self.gridData && self.gridData.length && self.gridData[0].filter_total ? self.gridData[0].filter_total : 0;
            let read = self.gridData && self.gridData.length && self.gridData[0].rows_total ? self.gridData[0].rows_total : 0;

            this.setState({
                read: read,
                arvestatud: arvestatud,
                soodustus: soodustus,
                summa: summa,
                filtri_read: filtri_read
            });
        }
        return (<ToolbarContainer>
                <BtnGetXml
                    value={'Saama CSV fail'}
                    onClick={this.onClickHandler}
                    showDate={false}
                    ref={`btn-getCsv`}
                />
            </ToolbarContainer>
        );

        return null;
    }

    //handler для события клик на кнопках панели
    onClickHandler() {
        const Doc = this.refs['register'];

        if (Doc.gridData && Doc.gridData.length) {
            //делаем редайрект на конфигурацию
            let sqlWhere = Doc.state.sqlWhere;
            let url = `/reports/kuutabeli_aruanne/${DocContext.userData.uuid}`;
            let params = encodeURIComponent(`${sqlWhere}`);
            let filter = encodeURIComponent(`${(JSON.stringify(Doc.filterData))}`);
            let fullUrl = sqlWhere ? `${url}/${filter}/${params}` : `${url}/${filter}`;
            window.open(fullUrl);

        } else {
            Doc.setState({
                warning: 'Mitte ühtegi kirjed leidnud', // строка извещений
                warningType: 'notValid',

            });
        }
    }



}


module.exports = (Documents);


