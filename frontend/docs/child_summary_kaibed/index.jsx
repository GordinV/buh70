'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const InputNumber = require('../../components/input-number/input-number.jsx');
const InputText = require('../../components/input-text/input-text.jsx');

const getSum = require('./../../../libs/getSum');

const styles = require('./styles');

const DOC_TYPE_ID = 'LAPS_KV_KAIBED';
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

        this.renderer = this.renderer.bind(this);
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
                {/*
                <InputText title="Filtri all / read kokku:"
                           name='read_kokku'
                           style={styles.total}
                           ref="input-read"
                           value={String(this.state.filtri_read + '/' + this.state.read) || 0}
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
*/}
            </div>
        )
    }

    renderer(self) {
        if (!self || !self.gridData || !self.gridData.length) {
            // пока нет данных
            this.setState({
                db: 0,
                kr: 0,
                mahakantud: 0,
                read: 0,
                filtri_read: 0
            });
            return null;
        }

        /*
                let db = self.gridData ? self.gridData[0].db_total : 0;
                let kr = self.gridData ? self.gridData[0].kr_total : 0;
                let mahakantud = self.gridData ? self.gridData[0].mahakantud_total : 0;


                let read = self.gridData && self.gridData.length && self.gridData[0].rows_total ? self.gridData[0].rows_total : 0;
                let filtri_read = self.gridData && self.gridData.length && self.gridData[0].filter_total ? self.gridData[0].filter_total : 0;

                this.setState({
                    db: db,
                    kr: kr,
                    mahakantud: mahakantud,
                    read: read,
                    filtri_read: filtri_read
                });
        */

        return (<div/>
        )
    }

}


module.exports = (Documents);


