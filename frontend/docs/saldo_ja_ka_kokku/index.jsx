'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const BtnGetXml = require('./../../components/button-register/button-task/index.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');
const InputNumber = require('../../components/input-number/input-number.jsx');
const InputText = require('../../components/input-text/input-text.jsx');
const Loading = require('../../components/loading/index.jsx');

const styles = require('./styles');
const DOC_TYPE_ID = 'SALDO_JA_KA_KOKKU';
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
        this.renderer = this.renderer.bind(this);
        this.state = {
            alg_db: 0,
            alg_kr: 0,
            db: 0,
            kr: 0,
            mahakantud: 0,
            lopp_db: 0,
            lopp_kr: 0,
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
                <InputNumber title="Alg.db kokku:"
                             name='alg_db_kokku'
                             style={styles.total}
                             ref="input-read"
                             value={Number(this.state.alg_db) || 0}
                             disabled={true}/>
                <InputNumber title="Alg.kr kokku:"
                             name='alg_kr_kokku'
                             style={styles.total}
                             ref="input-arvestatud"
                             value={Number(this.state.alg_kr) || 0}
                             disabled={true}/>
                <InputNumber title="Deebet kokku:"
                             name='db_kokku'
                             style={styles.total}
                             ref="input-db_kokku"
                             value={Number(this.state.db) || 0}
                             disabled={true}/>
                <InputNumber title="Kreedit kokku:"
                             name='kr_kokku'
                             style={styles.total}
                             ref="input-kr_kokku"
                             value={Number(this.state.kr) || 0}
                             disabled={true}/>
                <InputNumber title="Mahakantud kokku:"
                             name='mahakantud_kokku'
                             style={styles.total}
                             ref="input-mahandmine"
                             value={Number(this.state.mahakantud) || 0}
                             disabled={true}/>

                <InputNumber title="Lõpp db. kokku:"
                             name='lopp_db_kokku'
                             style={styles.total}
                             ref="input-laekumised"
                             value={Number(this.state.lopp_db) || 0}
                             disabled={true}/>
                <InputNumber title="Lõpp kr. kokku:"
                             name='kr_kokku'
                             style={styles.total}
                             ref="input-kr_kokku"
                             value={Number(this.state.lopp_kr) || 0}
                             disabled={true}/>
            </div>
        )
    }

    renderer(self) {

        if (!self || !self.gridData || !self.gridData.length) {
            // пока нет данных
            this.setState({
                alg_db: 0,
                alg_kr: 0,
                db: 0,
                kr: 0,
                mahakantud: 0,
                lopp_db: 0,
                lopp_kr: 0,
                read: 0,
                filtri_read: 0
            });
            return null;
        }

        let alg_db = self.gridData ? self.gridData[0].alg_db_total : 0;
        let alg_kr = self.gridData ? self.gridData[0].alg_kr_total : 0;
        let db = self.gridData ? self.gridData[0].db_total : 0;
        let kr = self.gridData ? self.gridData[0].kr_total : 0;
        let mahakantud = self.gridData ? self.gridData[0].mahakantud_total : 0;
        let lopp_db = self.gridData ? self.gridData[0].lopp_db_total : 0;
        let lopp_kr = self.gridData ? self.gridData[0].lopp_kr_total : 0;


        let read = self.gridData && self.gridData.length && self.gridData[0].rows_total ? self.gridData[0].rows_total : 0;
        let filtri_read = self.gridData && self.gridData.length && self.gridData[0].filter_total ? self.gridData[0].filter_total : 0;

        this.setState({
            alg_db: alg_db,
            alg_kr: alg_kr,
            db: db,
            kr: kr,
            mahakantud: mahakantud,
            lopp_db: lopp_db,
            lopp_kr: lopp_kr,
            read: read,
            filtri_read: filtri_read
        });

        return null;
    }


}


module.exports = (Documents);


