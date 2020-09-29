'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const BtnTask = require('./../../components/button-register/button-task/index.jsx');

const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');
const ButtonUpload = require('./../../components/upload_button/index.jsx');
const InputText = require('../../components/input-text/input-text.jsx');

const styles = require('./styles');
const gridConfig = require('./../../../models/lapsed/lapse_kaart').grid.gridConfiguration;
const DOC_TYPE_ID = 'LAPSE_KAART';

const DocRights = require('./../../../config/doc_rights');
const checkRights = require('./../../../libs/checkRights');
const DocContext = require('./../../doc-context.js');

const docRights = DocRights[DOC_TYPE_ID] ? DocRights[DOC_TYPE_ID] : [];

/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.onClickHandler = this.onClickHandler.bind(this);
        this.onClickExport = this.onClickExport.bind(this);
        this.onClickTeenusteTahtaegHandler = this.onClickTeenusteTahtaegHandler.bind(this);
        this.renderer = this.renderer.bind(this);
        this.state = {
            read: 0,
            filtri_read: 0
        };

    }

    render() {
        return (<div><DocumentRegister initData={this.props.initData}
                                       gridConfig = {gridConfig}
                                       userData={this.props.userData}
                                       history={this.props.history ? this.props.history : null}
                                       module={this.props.module}
                                       ref='register'
                                       docTypeId={DOC_TYPE_ID}
                                       style={styles}
                                       render={this.renderer}/>
                <InputText title="Filtri all / read kokku:"
                           name='read_kokku'
                           style={styles.total}
                           ref="input-read"
                           value={String(this.state.filtri_read + '/' + this.state.read)}
                           disabled={true}/>
            </div>
        )
    }

    renderer(self) {
        let userRoles = DocContext.userData ? DocContext.userData.roles : [];
        if (self && self.gridData )  {
            let rows_total = self.gridData.length && self.gridData[0].rows_total ? self.gridData[0].rows_total: 0;
            this.setState({
                read: rows_total,
                filtri_read: self.gridData.length && self.gridData[0].filter_total ? self.gridData[0].filter_total : rows_total
            });
        }

        return (
            <ToolbarContainer>
                {checkRights(userRoles, docRights, 'muudaTeenusteTahtaeg') ?
                    <BtnTask
                        value={'Muuda teenuste tähtaeg'}
                        onClick={this.onClickTeenusteTahtaegHandler}
                        showDate={true}
                        showKogus={false}
                        ref={`btn-teenuste_tahtaeg`}
                    /> : null}

                {checkRights(userRoles, docRights, 'muudaEttemaksuPeriod') ?
                    <BtnTask
                        value={'Muuda ettemaksu period'}
                        onClick={this.onClickHandler.bind(this, 'muudaEttemaks')}
                        showDate={false}
                        showKogus={true}
                        ref={`btn-ettemaksu_period`}
                    /> : null}
                {checkRights(userRoles, docRights, 'importTeenused') ?
                    <ButtonUpload
                        ref='btnUpload'
                        docTypeId={DOC_TYPE_ID}
                        onClick={this.handleClick}
                        show={true}
                        mimeTypes={'.csv'}
                    /> : null}
                <BtnTask
                    value={'Saama CSV fail'}
                    onClick={this.onClickExport}
                    showDate={false}
                    showKogus={false}
                    ref={`btn-ettemaksu_period`}
                />
            </ToolbarContainer>
        )
    }

    onClickHandler(event, ettemaksuPeriod) {

        const Doc = this.refs['register'];

        // собираем параметры
        const ids = [];
        Doc.gridData.filter(row => {
            if (row.ettemaks && row.select) {
                return row;
            }
        }).forEach(row => {
            ids.push(row.id);
        });


        // отправляем запрос на выполнение
        Doc.fetchData(`calc/muuda_ettemaksu_period`, {docs: ids, ettemaksuPeriod: ettemaksuPeriod}).then((data) => {

            if (data.result) {
                Doc.setState({warning: `Kokku arvestatud: ${data.result}`, warningType: 'ok'});

            } else {
                Doc.setState({warning: `Tekkis viga: ${data.error_message}`, warningType: 'notValid'});
            }

        });
    }

    onClickExport(event) {
        const Doc = this.refs['register'];

        if (Doc.gridData && Doc.gridData.length) {

            //делаем редайрект на конфигурацию


            let sqlWhere = Doc.state.sqlWhere;
            let params = encodeURIComponent(`${sqlWhere}`);
            let url = `/reports/lapse_kaart/${DocContext.userData.uuid}`;

            let filter = encodeURIComponent(`${(JSON.stringify(Doc.filterData))}`);
            let fullUrl = sqlWhere ? `${url}/${filter}/${params}` : `${url}/${filter}`;

            window.open(fullUrl);

        } else {
            Doc.setState({
                warning: 'Mitte ühtegi teenused leidnum', // строка извещений
                warningType: 'notValid',

            });
        }
    }

    onClickTeenusteTahtaegHandler(event, teenusteTahtaeg) {

        const Doc = this.refs['register'];

        // собираем параметры
        const ids = [];
        Doc.gridData.filter(row => {
            if (row.select) {
                return row;
            }
        }).forEach(row => {
            ids.push(row.id);
        });


        // отправляем запрос на выполнение
        Doc.fetchData(`calc/muuda_teenuste_tahtaeg`, {docs: ids, teenusteTahtaeg: teenusteTahtaeg}).then((data) => {

            if (data.result) {
                Doc.btnRefreshClick();
                Doc.setState({warning: `Kokku muudetud: ${data.result}`, warningType: 'ok'});

            } else {
                Doc.setState({warning: `Tekkis viga: ${data.error_message}`, warningType: 'notValid'});
            }

        });
    }

}


module.exports = (Documents);


