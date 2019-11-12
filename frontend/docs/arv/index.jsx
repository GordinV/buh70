'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');
const BtnSettings = require('./../../components/button-register/button-settings/index.jsx');
const BtnPrint = require('./../../components/button-register/button-register-print/button-register-print.jsx');

const styles = require('./arv-register-styles');
const DOC_TYPE_ID = 'ARV';
const DocContext = require('./../../doc-context.js');

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
                                 history = {this.props.history ? this.props.history: null}
                                 module = {this.props.module}
                                 ref = 'register'
                                 docTypeId={DOC_TYPE_ID}
                                 style={styles}
                                 render={this.renderer}/>;
    }

    renderer(self) {
        return (<ToolbarContainer>
            <BtnPrint
                onClick={this.onClickHandler}
                value={'Trükk kõik valitud arved'}
                />
            <BtnSettings
                history={self.props.history ? self.props.history : null}
                onClick={this.onClickHandler}
                ref='btnSettings'
                value='Häälestamine'
            />
        </ToolbarContainer>)
    }

    //handler для события клик на кнопках панели
    onClickHandler (event) {
        switch (event) {
            case 'settings':
                //делаем редайрект на конфигурацию
                this.props.history.push(`/${this.props.module}/config/${DocContext.userData.asutusId}`);
            break;
            case 'print':
                const Doc = this.refs['register'];

                let ids = [];

                // будет выведено на печать выбранные и только для печати счета
                Doc.gridData.forEach(row => {
                    if (row.select && row.kas_paberil) {
                        // выбрано для печати
                        ids.push(row.id);
                    }
                });

                if (ids.length > 0) {
                    Doc.setState({warning: `Leidsin ${ids.length} arveid printimiseks`, // строка извещений
                        warningType: 'ok',
                    });

                    let url = `/multiple_print/${DOC_TYPE_ID}/${DocContext.userData.uuid}/${ids}`;
                    window.open(`${url}`);
                } else {
                    Doc.setState({warning: 'Mitte ühtegi arve leidnum', // строка извещений
                        warningType: 'notValid',
                    });
                }

                break;

        }
    }
}


module.exports = (Documents);


