'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const BtnGetXml = require('./../../components/button-register/button-task/index.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');
const InputNumber = require('../../components/input-number/input-number.jsx');


const DocContext = require('./../../doc-context.js');

const styles = require('./styles');
const DOC_TYPE_ID = 'CHILD_AGE';
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
                             value={Number(this.state.read) || 0}
                             disabled={true}/>

            </div>
        )
    }

    renderer(self) {
        if (self.gridData && self.gridData.length) {
            this.setState({read: self.gridData.length});
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
            let url = `/reports/child_age/${DocContext.userData.uuid}`;
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


