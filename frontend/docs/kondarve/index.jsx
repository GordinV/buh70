'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const BtnGetXml = require('./../../components/button-register/button-task/index.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');
const DocContext = require('./../../doc-context.js');
const InputNumber = require('../../components/input-number/input-number.jsx');
const InputText = require('../../components/input-text/input-text.jsx');

const styles = require('./styles');
const DOC_TYPE_ID = 'KONDARVE';
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
        this.onClickHandler = this.onClickHandler.bind(this);
        this.renderer = this.renderer.bind(this);
        this.renderKontod = this.renderKontod.bind(this);
        this.state = {
            summa: 0,
            read: 0,
            filtri_read: 0
        };
        this.kontod = [];
    }

    render() {
        console.log('render kondarve');
        try {
            return (
                <div>
                    <DocumentRegister initData={this.props.initData}
                                      history={this.props.history ? this.props.history : null}
                                      module={this.props.module}
                                      ref='register'
                                      toolbarProps={TOOLBAR_PROPS}
                                      docTypeId={DOC_TYPE_ID}
                                      style={styles}
                                      render={this.renderer}/>;

                    <InputText title="Filtri all / read kokku:"
                               name='read_kokku'
                               style={styles.total}
                               ref="input-read"
                               value={String(this.state.filtri_read + '/' + this.state.read) || 0}
                               disabled={true}/>
                    <InputNumber title="Summa kokku:"
                                 name='summa_kokku'
                                 style={styles.total}
                                 ref="input-read"
                                 value={Number(this.state.summa) || 0}
                                 disabled={true}/>
                    {this.kontod.length ? this.renderKontod() :null}
                </div>
            )
        } catch (e) {
            return <div>Viga</div>
        }

    }

    renderer(self) {
        if (!self || !self.gridData || !self.gridData.length) {
            // пока нет данных
            this.setState({
                summa: 0,
                read: 0,
                filtri_read: 0
            });
            return null;
        }

        let summa = self.gridData ? self.gridData[0].summa_total : 0;

        let read = self.gridData && self.gridData.length && self.gridData[0].rows_total ? self.gridData[0].rows_total : 0;
        let filtri_read = self.gridData && self.gridData.length && self.gridData[0].filter_total ? self.gridData[0].filter_total : 0;

        if (summa) {
            try {
                this.kontod = self.gridData[0].kontod;
            } catch (e) {
                console.error('Kontod puuduvad', e);
            }
        }

        this.setState({
            summa: summa,
            read: read,
            filtri_read: filtri_read
        });


        return (<ToolbarContainer>
                <BtnGetXml
                    value={'Saama CSV fail'}
                    onClick={this.onClickHandler}
                    showDate={false}
                    ref={`btn-geCsv`}
                />
            </ToolbarContainer>
        );
    }

    renderKontod() {
        return this.kontod.map(konto => {
                return (
                    <div>
                        <InputNumber title={"Kokku konto " + konto.konto}
                                     name={'konto_kokku_' + konto.konto}
                                     style={styles.total}
                                     ref="input-read"
                                     value={Number(konto.summa) || 0}
                                     disabled={true}/>
                    </div>
                )
            }
        )
    }


    //handler для события клик на кнопках панели
    onClickHandler() {
        const Doc = this.refs['register'];

        if (Doc.gridData && Doc.gridData.length) {
            //делаем редайрект на конфигурацию
            let sqlWhere = Doc.state.sqlWhere;
            let url = `/reports/kondarve/${DocContext.userData.uuid}`;
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


