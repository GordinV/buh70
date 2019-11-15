'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');
const BtnSettings = require('./../../components/button-register/button-settings/index.jsx');
const BtnPrint = require('./../../components/button-register/button-register-print/button-register-print.jsx');
const BtnEmail = require('./../../components/button-register/button-email/index.jsx');

const styles = require('./arv-register-styles');
const DOC_TYPE_ID = 'ARV';
const DocContext = require('./../../doc-context.js');
const EVENTS = [
    {name: 'Häälestamine', method: null, docTypeId: null},
    {name: 'Trükk kõik valitud arved', method: null, docTypeId: null},
    {name: 'Email kõik valitud arved', method: null, docTypeId: null},
];

/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.onClickHandler = this.onClickHandler.bind(this);
        this.renderer = this.renderer.bind(this)
    }

    render() {
        return <DocumentRegister initData={this.props.initData}
                                 history={this.props.history ? this.props.history : null}
                                 module={this.props.module}
                                 ref='register'
                                 docTypeId={DOC_TYPE_ID}
                                 style={styles}
                                 render={this.renderer}/>;
    }

    renderer(self) {
        return (<ToolbarContainer>
            <BtnEmail
                onClick={this.onClickHandler}
                ref='btnEmail'
                value={EVENTS[2].name}
            />
            <BtnPrint
                onClick={this.onClickHandler}
                ref='btnPrint'
                value={EVENTS[1].name}
            />
            <BtnSettings
                history={self.props.history ? self.props.history : null}
                onClick={this.onClickHandler}
                ref='btnSettings'
                value={EVENTS[0].name}
            />
        </ToolbarContainer>)
    }

    //handler для события клик на кнопках панели
    onClickHandler(event) {
        const ids = []; // сюда пишем ид счетом, которые под обработку
        const Doc = this.refs['register'];

        // будет выведено на печать выбранные и только для печати счета
        Doc.gridData.forEach(row => {
            if (row.select && row.kas_paberil) {
                // выбрано для печати
                ids.push(row.id);
            }
        });

        switch (event) {
            case EVENTS[0].name:
                //делаем редайрект на конфигурацию
                this.props.history.push(`/${this.props.module}/config/${DocContext.userData.asutusId}`);
                break;
            case EVENTS[1].name:
                // Print

                // будет выведено на печать выбранные и только для печати счета
                Doc.gridData.forEach(row => {
                    if (row.select && row.kas_paberil) {
                        // выбрано для печати
                        ids.push(row.id);
                    }
                });

                if (ids.length > 0) {
                    Doc.setState({
                        warning: `Leidsin ${ids.length} arveid printimiseks`, // строка извещений
                        warningType: 'ok',
                    });

                    let url = `/multiple_print/${DOC_TYPE_ID}/${DocContext.userData.uuid}/${ids}`;
                    window.open(`${url}`);
                } else {
                    Doc.setState({
                        warning: 'Mitte ühtegi arve leidnum', // строка извещений
                        warningType: 'notValid',
                    });
                }

                break;
            case EVENTS[2].name:
                //emails

                // будет отправлено на почту  выбранные и только для эл.почты счета
                Doc.gridData.forEach(row => {
                    if (row.select && row.kas_email) {
                        // выбрано для печати
                        ids.push(row.id);
                    }
                });

                if (!ids.length) {
                    Doc.setState({
                        warning: 'Mitte ühtegi arve leidnum', // строка извещений
                        warningType: 'notValid',
                    });
                } else {
                    // отправляем запрос на выполнение

                    Doc.fetchData(`email`, ids).then((data) => {
                        if (data.result) {
                            Doc.setState({warning: `Kokku saadetud arveid emailga: ${data.result}`, warningType: 'ok'});

                        } else {
                            Doc.setState({warning: `Tekkis viga: ${data.error_message}`, warningType: 'notValid'});
                        }

                    });


                }

                break;

        }
    }
}


module.exports = (Documents);


