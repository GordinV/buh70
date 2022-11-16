'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const BtnGetXml = require('./../../components/button-register/button-task/index.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');
const InputNumber = require('../../components/input-number/input-number.jsx');
const InputText = require('../../components/input-text/input-text.jsx');
const Loading = require('../../components/loading/index.jsx');

const styles = require('./styles');
const DOC_TYPE_ID = 'SALDO_JA_KAIVE';
const TOOLBAR_PROPS = {
    add: false,
    edit: false,
    delete: false,
    start: false,
    print: true,
    email: true
};
const DocContext = require('./../../doc-context.js');

/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.onClickHandler = this.onClickHandler.bind(this);
        this.renderer = this.renderer.bind(this);
        this.state = {
            alg_saldo: 0,
            arvestatud: 0,
            arv_kokku: 0,
            umberarvestus: 0,
            soodustus: 0,
            laekumised: 0,
            mahakantud: 0,
            tagastused: 0,
            jaak: 0,
            read: 0,
            filtri_read: 0
        };

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
                <InputNumber title="Alg.saldo kokku:"
                             name='alg_saldo_kokku'
                             style={styles.total}
                             ref="input-read"
                             value={Number(this.state.alg_saldo) || 0}
                             disabled={true}/>
                <InputNumber title="Arvestatud kokku:"
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
                <InputNumber title="Ümberarvestus kokku:"
                             name='umberarvestus_kokku'
                             style={styles.total}
                             ref="input-umberarvestus"
                             value={Number(this.state.umberarvestus) || 0}
                             disabled={true}/>
                <InputNumber title="Kokku arvestatud (kokku)"
                             name='arv_kokku'
                             style={styles.total}
                             ref="input-arv_kokku"
                             value={(Number(this.state.arvestatud)+Number(this.state.soodustus)+Number(this.state.umberarvestus)).toFixed(2) || 0}
                             disabled={true}/>

                <InputNumber title="Laekumised kokku:"
                             name='laekumised_kokku'
                             style={styles.total}
                             ref="input-laekumised"
                             value={Number(this.state.laekumised) || 0}
                             disabled={true}/>
                <InputNumber title="Tagastused kokku:"
                             name='tagastused_kokku'
                             style={styles.total}
                             ref="input-tagastused"
                             value={Number(this.state.tagastused) || 0}
                             disabled={true}/>
                <InputNumber title="Mahakantud kokku:"
                             name='mahakantud_kokku'
                             style={styles.total}
                             ref="input-mahandmine"
                             value={Number(this.state.mahakantud) || 0}
                             disabled={true}/>
                <InputNumber title="Jääk kokku:"
                             name='jaak_kokku'
                             style={styles.total}
                             ref="input-jaak"
                             value={Number(this.state.jaak) || 0}
                             disabled={true}/>
            </div>
        )
    }

    renderer(self) {

        if (!self || !self.gridData || !self.gridData.length) {
            // пока нет данных
            this.setState({
                alg_saldo: 0,
                arvestatud: 0,
                umberarvestus: 0,
                soodustus: 0,
                arv_kokku: 0,
                arv_ja_soodustus: 0,
                laekumised: 0,
                mahakantud: 0,
                tagastused: 0,
                jaak: 0,
                read: 0,
                filtri_read: 0
            });
            return null;
        }

        let alg_saldo = self.gridData ? self.gridData[0].alg_saldo_total : 0;
        let arvestatud = self.gridData ? self.gridData[0].arvestatud_total : 0;
        let umberarvestus = self.gridData ? self.gridData[0].umberarvestus_total : 0;
        let soodustus = self.gridData ? self.gridData[0].soodustus_total : 0;
        let arv_ja_soodustus = self.gridData ? self.gridData[0].arv_ja_soodustus_total : 0;
        let laekumised = self.gridData ? self.gridData[0].laekumised_total : 0;
        let mahakantud = self.gridData ? self.gridData[0].mahakantud_total : 0;
        let tagastused = self.gridData ? self.gridData[0].tagastused_total : 0;
        let jaak = self.gridData ? self.gridData[0].jaak_total : 0;


        let read = self.gridData && self.gridData.length && self.gridData[0].rows_total ? self.gridData[0].rows_total : 0;
        let filtri_read = self.gridData && self.gridData.length && self.gridData[0].filter_total ? self.gridData[0].filter_total : 0;

        this.setState({
            alg_saldo: alg_saldo,
            arvestatud: arvestatud,
            umberarvestus: umberarvestus,
            soodustus: soodustus,
            arv_kokku: arvestatud + soodustus + umberarvestus,
            arv_ja_soodustus: arv_ja_soodustus,
            laekumised: laekumised,
            mahakantud: mahakantud,
            tagastused: tagastused,
            jaak: jaak,
            read: read,
            filtri_read: filtri_read
        });

        return (<ToolbarContainer>
                <BtnGetXml
                    value={'Saama CSV fail'}
                    onClick={this.onClickHandler}
                    showDate={false}
                    ref={`btn-getCsv`}
                />
            </ToolbarContainer>
        )
    }

    //handler для события клик на кнопках панели
    onClickHandler() {
        const Doc = this.refs['register'];

        if (Doc.gridData && Doc.gridData.length) {
            //делаем редайрект на конфигурацию
            let sqlWhere = Doc.state.sqlWhere;
            let url = `/reports/saldo_ja_kaive/${DocContext.userData.uuid}`;
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


