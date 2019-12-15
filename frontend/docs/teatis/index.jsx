'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const BtnArvesta = require('./../../components/button-register/button-task/index.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');
const BtnEmail = require('./../../components/button-register/button-email/index.jsx');
const BtnPrint = require('./../../components/button-register/button-register-print/button-register-print.jsx');
const DocContext = require('./../../doc-context.js');

const styles = require('./styles');
const DOC_TYPE_ID = 'TEATIS';
const EVENTS = [
    {name: 'Tabeli koostamine', method: 'arvestaTaabel', docTypeId: 'lapse_taabel'},
    {name: 'Arve koostamine', method: 'koostaArve', docTypeId: 'arv'},
    {name: 'Ettemaksuarve koostamine', method: 'koostaEttemaksuArve', docTypeId: 'arv'},
];


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
        return (
            <ToolbarContainer>
                <BtnArvesta
                    value={'Koosta teatised'}
                    onClick={this.onClickHandler}
                    ref={`btn-teatis`}
                />
                <BtnEmail
                    onClick={this.onClickHandler}
                    ref='btnEmail'
                    value={'Email kõik valitud teatised'}
                />
                <BtnPrint
                    onClick={this.onClickHandler}
                    ref='btnPrint'
                    value={'Trükk kõik valitud teatised'}
                />

            </ToolbarContainer>
        )
    }

    onClickHandler(event, seisuga) {
        const Doc = this.refs['register'];
        let ids = new Set; // сюда пишем ид счетом, которые под обработку

        switch (event) {
            case 'Koosta teatised':

                // отправляем запрос на выполнение
                Doc.fetchData(`calc/koostaTeatis`, {seisuga: seisuga}).then((data) => {
                    if (data.result) {
                        Doc.setState({warning: `Kokku arvestatud: ${data.result}`, warningType: 'ok'});
                    } else {
                        if (data.error_message) {
                            Doc.setState({warning: `Tekkis viga: ${data.error_message}`, warningType: 'error'});
                        } else {
                            Doc.setState({warning: `0 dokumendid koostatud`, warningType: 'notValid'});
                        }
                    }
                });
                break;
            case 'Email kõik valitud teatised':

                // будет отправлено на почту  выбранные и только для эл.почты счета
                Doc.gridData.forEach(row => {
                    if (row.select) {
                        // выбрано для печати
                        ids.add(row.id);
                    }
                });

                // конвертация в массив
                ids = Array.from(ids);

                if (!ids.length) {
                    Doc.setState({
                        warning: 'Mitte ühtegi arve leidnum', // строка извещений
                        warningType: 'notValid',
                    });
                } else {
                    // отправляем запрос на выполнение

                    Doc.fetchData(`email/teatis`, ids).then((data) => {
                        if (data.result) {
                            Doc.setState({warning: `Kokku saadetud teatised emailga: ${data.result}`, warningType: 'ok'});

                        } else {
                            console.error('email error', data);
                            Doc.setState({warning: `Tekkis viga: ${data.error_message}`, warningType: 'error'});
                        }

                    }).catch(error => {
                        console.error('email error', error);
                        Doc.setState({warning: `Tekkis viga: ${error}`, warningType: 'error'});

                    });


                }
                break;
            case 'Trükk kõik valitud teatised':
                // Print

                // будет выведено на печать выбранные и только для печати счета
                Doc.gridData.forEach(row => {
                    if (row.select) {
                        // выбрано для печати
                        ids.add(row.id);
                    }
                });
                // конвертация в массив
                ids = Array.from(ids);

                if (ids.length > 0) {
                    Doc.setState({
                        warning: `Leidsin ${ids.length} teatised printimiseks`, // строка извещений
                        warningType: 'ok',
                    });

                    let url = `/multiple_print/${DOC_TYPE_ID}/${DocContext.userData.uuid}/${ids}`;
                    window.open(`${url}`);
                } else {
                    Doc.setState({
                        warning: 'Mitte ühtegi dokumend leidnum', // строка извещений
                        warningType: 'notValid',
                    });
                }

        }
        Doc.fetchData('selectDocs');
    }
}


module.exports = (Documents);

