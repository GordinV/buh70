'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const InputNumber = require('../../components/input-number/input-number.jsx');

const getSum = require('./../../../libs/getSum');
const styles = require('./vmk-register-styles');
const DocContext = require('./../../doc-context.js');

const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');
const BtnSepa = require('./../../components/button-register/button-earve/index.jsx');
const DOC_TYPE_ID = 'VMK';

/**
 * Класс реализует документ приходного платежного ордера.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.onClickHandler = this.onClickHandler.bind(this);
        this.renderer = this.renderer.bind(this);
        this.state = {
            summa: 0,
            read: 0
        };

    }

    render() {
        return (
            <div>
                <DocumentRegister initData={this.props.initData}
                                  ref='register'
                                  history={this.props.history ? this.props.history : null}
                                  docTypeId={DOC_TYPE_ID}
                                  module={this.props.module}
                                  style={styles}
                                  render={this.renderer}/>
                <InputNumber title="Read kokku:"
                             name='read_kokku'
                             style={styles.total}
                             ref="input-read"
                             value={Number(this.state.read) || 0}
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
        let summa = self.gridData ? getSum (self.gridData,'kreedit') : 0;
        if (summa) {
            this.setState({summa: summa, read: self.gridData.length});
        }

        return (
            <ToolbarContainer>
                <BtnSepa
                    onClick={this.onClickHandler}
                    phrase={`Kas laadida XML fail?`}
                    ref='btnSepaXML'
                    value={'Saama XML (SEPA) kõik valitud maksed'}
                />
            </ToolbarContainer>
        );
    }

    //handler для события клик на кнопках панели
    onClickHandler(event) {
        let ids = new Set; // сюда пишем ид счетом, которые под обработку

        const Doc = this.refs['register'];
        // будет отправлено на почту  выбранные и только для эл.почты счета
        Doc.gridData.forEach(row => {
            // выбрано для печати
            ids.add(row.id);
        });

        // конвертация в массив
        ids = Array.from(ids);

        if (!ids.length) {
            Doc.setState({
                warning: 'Mitte ühtegi makse leidnum', // строка извещений
                warningType: 'notValid',
            });
        } else {
            // отправляем запрос на выполнение
            Doc.setState({
                warning: `Leidsin ${ids.length} maksed`, // строка извещений
                warningType: 'ok',
            });

            let url = `/sepa/${DocContext.userData.uuid}/${ids}`;
            window.open(`${url}`);
        }
    }
}

module.exports = (Documents);


