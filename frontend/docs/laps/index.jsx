'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const BtnArvesta = require('./../../components/button-register/button-task/index.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');

const styles = require('./laps-register-styles');
const DOC_TYPE_ID = 'LAPS';


/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.onClickHandler = this.onClickHandler.bind(this);
        this.renderer = this.renderer.bind(this);
    }

    render() {
        return (
            <DocumentRegister initData={this.props.initData}
                              history={this.props.history ? this.props.history : null}
                              module={this.props.module}
                              ref='register'
                              docTypeId={DOC_TYPE_ID}
                              style={styles}
                              render={this.renderer}/>
        );
    }

    renderer() {
        const Doc = this.refs['register'];

        return (
            <ToolbarContainer>
                <BtnArvesta
                    value={'Tabeli koostamine'}
                    onClick={this.onClickHandler}
                />
            </ToolbarContainer>
        )
    }

    onClickHandler(event) {
        const Doc = this.refs['register'];

        // собираем параметры
        const ids = [];
        Doc.gridData.filter(row => row.select).forEach(row => {
            ids.push(row.id);
        });

        // отправляем запрос на выполнение
        Doc.fetchData(`calc/arvestaTaabel`, ids).then((data) => {
            if (data.result) {
                Doc.setState({warning: `Kokku arvestatud: ${data.result}, suunatamine...`, warningType: 'ok'});

                // ждем 10 сек и редайрект на табеля
                setTimeout(() => {
                    this.props.history.push(`/lapsed/lapse_taabel`);
                }, 1000 * 5);
            } else {
                Doc.setState({warning: `Tekkis viga: ${data.error_message}`, warningType: 'notValid'});
            }

        });
    }
}


module.exports = (Documents);

