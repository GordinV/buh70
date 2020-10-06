'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const BtnGetXml = require('./../../components/button-register/button-task/index.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');
const InputNumber = require('../../components/input-number/input-number.jsx');
const getSum = require('./../../../libs/getSum');


const DocContext = require('./../../doc-context.js');

const styles = require('./styles');

const DOC_TYPE_ID = 'EBATOENAOLISED';
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
        this.state = {
            noude_50: 0,
            noude_100: 0,
            jaak: 0,
            read: 0
        };

    }

    render() {
        return (
            <div>
                <DocumentRegister initData={this.props.initData}
                                  history={this.props.history ? this.props.history : null}
                                  module={this.props.module}
                                  ref='register'
                                  docTypeId={DOC_TYPE_ID}
                                  toolbarProps={TOOLBAR_PROPS}
                                  style={styles}
                                  render={this.renderer}/>
                <InputNumber title="Read kokku:"
                             name='read_kokku'
                             style={styles.total}
                             ref="input-read"
                             value={Number(this.state.read) || 0}
                             disabled={true}/>
                <InputNumber title="Nõude 50% kokku:"
                             name='noude_50_kokku'
                             style={styles.total}
                             ref="input-noude_50"
                             value={Number(this.state.noude_50).toFixed(2) || 0}
                             disabled={true}/>
                <InputNumber title="Nõude 100% kokku:"
                             name='noude_100_kokku'
                             style={styles.total}
                             ref="input-noude_100"
                             value={Number(this.state.noude_100).toFixed(2) || 0}
                             disabled={true}/>
                <InputNumber title="Jääk kokku:"
                             name='jaak_kokku'
                             style={styles.total}
                             ref="input-jaak"
                             value={Number(this.state.jaak).toFixed(2) || 0}
                             disabled={true}/>

            </div>
        )
    }

    renderer(self) {
        let noude_50 = self.gridData ? getSum (self.gridData,'noude_50') : 0;
        let noude_100 = self.gridData ? getSum (self.gridData,'noude_100') : 0;
        let jaak = self.gridData ? getSum (self.gridData,'jaak') : 0;
        if (self.gridData) {
            this.setState({
                noude_50: noude_50,
                noude_100: noude_100,
                jaak: jaak,
                read: self.gridData.length});
        }

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

//handler для события клик на кнопках панели
    onClickHandler() {
        const Doc = this.refs['register'];

        if (Doc.gridData && Doc.gridData.length) {
            //делаем редайрект на конфигурацию
            let sqlWhere = Doc.state.sqlWhere;
            let url = `/reports/ebatoenaolised/${DocContext.userData.uuid}`;
            let params = encodeURIComponent(`${sqlWhere}`);
            let filter = encodeURIComponent(`${(JSON.stringify(Doc.filterData))}`);
            let fullUrl = sqlWhere ? `${url}/${filter}/${params}`: `${url}/${filter}`;
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


