'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const BtnGetXml = require('./../../components/button-register/button-task/index.jsx');
const BtnGetDocs = require('./../../components/button-register/button_analuus/index.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');
const getSum = require('./../../../libs/getSum');
const InputNumber = require('../../components/input-number/input-number.jsx');

const styles = require('./styles');
const DOC_TYPE_ID = 'INF3';
const DocContext = require('./../../doc-context.js');
const TOOLBAR_PROPS = {
    add: false,
    edit: false,
    delete: false,
    start: false,
    print: true,
    email: true
};

const INF3_ANALUUS_FILTER = require('./../../../config/constants').INF3_ANALUUS.CONFIG;

/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.onClickHandler = this.onClickHandler.bind(this);
        this.renderer = this.renderer.bind(this);
        this.setFilterData = this.setFilterData.bind(this);
        this.state = {
            summa: 0,
            read: 0
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
                <InputNumber title="Read kokku:"
                             name='read_kokku'
                             style={styles.total}
                             ref="input-read"
                             value={Number(this.state.read).toFixed(2) || 0}
                             disabled={true}/>
                <InputNumber title="Summa kokku:"
                             name='summa_kokku'
                             style={styles.total}
                             ref="input-summa"
                             value={Number(this.state.summa).toFixed(2) || 0}
                             disabled={true}/>

            </div>
        )
    }

    renderer(self) {
        let summa = self.gridData ? getSum(self.gridData, 'summa') : 0;
        if (summa) {
            this.setState({summa: summa, read: self.gridData.length});
        }

        let sqlWhere = ' where false';
        let idx = self.state.idx;
        let row = self.gridData[idx];

        if (row ) {
            sqlWhere = this.setFilterData(row);
        }

        return (<ToolbarContainer>
                <BtnGetXml
                    value={'Saama XML fail'}
                    showDate={false}
                    onClick={this.onClickHandler}
                    ref={`btn-getXml`}
                />
                <BtnGetDocs
                    value={'Rea analüüs'}
                    onClick={this.onClickHandler}
                    ref={`btn-analuus`}
                    sqlWhere={sqlWhere}
                    filterData = {INF3_ANALUUS_FILTER}
                />
            </ToolbarContainer>
        )
    }

    setFilterData(row) {
        let sqlWhere = `where kas_inf3 = 'JAH' and lapse_isikukood ilike '%${row.lapse_isikukood}%' and number not ilike '%INF3 deklaratsioon%'`;
        let kpv_index = INF3_ANALUUS_FILTER.findIndex(row=>  row.id === 'kpv');
        let aasta_index = INF3_ANALUUS_FILTER.findIndex(row=>  row.id === 'aasta');
        let lapseIk_index = INF3_ANALUUS_FILTER.findIndex(row=>  row.id === 'lapse_isikukood');
        let maksjaIk_index = INF3_ANALUUS_FILTER.findIndex(row=>  row.id === 'maksja_isikukood');

        INF3_ANALUUS_FILTER[aasta_index].value =  row.aasta;
        INF3_ANALUUS_FILTER[lapseIk_index].value =  row.lapse_isikukood;
        INF3_ANALUUS_FILTER[maksjaIk_index].value =  row.maksja_isikukood;

        INF3_ANALUUS_FILTER[kpv_index].kpv_start = row.aasta + '-01-01';
        if (INF3_ANALUUS_FILTER[kpv_index].kpv_start === '2023-01-01') {
            INF3_ANALUUS_FILTER[kpv_index].kpv_start = '2022-12-31';
        }
        INF3_ANALUUS_FILTER[kpv_index].kpv_end = row.aasta + '-12-31';
        INF3_ANALUUS_FILTER[kpv_index].value =  INF3_ANALUUS_FILTER[kpv_index].kpv_start;
        INF3_ANALUUS_FILTER[kpv_index].start =  INF3_ANALUUS_FILTER[kpv_index].kpv_start;
        INF3_ANALUUS_FILTER[kpv_index].end = INF3_ANALUUS_FILTER[kpv_index].kpv_end;

        return sqlWhere;
    }


    //handler для события клик на кнопках панели
    onClickHandler(event) {
        const Doc = this.refs['register'];

        if (event == 'Saama XML fail') {

            if (Doc.gridData && Doc.gridData.length) {
                //делаем редайрект на конфигурацию
                let sqlWhere = Doc.state.sqlWhere;
                let url = `/reports/inf3/${DocContext.userData.uuid}`;
                let params = encodeURIComponent(`${sqlWhere}`);
                let filter = encodeURIComponent(`${(JSON.stringify(Doc.filterData))}`);
                let fullUrl = sqlWhere ? `${url}/${filter}/${params}` : `${url}/${filter}`;

                window.open(fullUrl);
            } else {
                Doc.setState({
                    warning: 'Mitte ühtegi INF teenused leidnum', // строка извещений
                    warningType: 'notValid',

                });
            }
        }

    }


}


module.exports = (Documents);


