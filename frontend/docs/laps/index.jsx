'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const BtnArvesta = require('./../../components/button-register/button-task/index.jsx');
const ButtonUpload = require('./../../components/upload_button/index.jsx');
const InputText = require('../../components/input-text/input-text.jsx');

const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');
const ModalReport = require('./../../components/modalpage/modalpage-report/index.jsx');

const styles = require('./laps-register-styles');

const DOC_TYPE_ID = 'LAPS';
const EVENTS = require('./../../../config/constants').events[DOC_TYPE_ID];

const DocRights = require('./../../../config/doc_rights');
const checkRights = require('./../../../libs/checkRights');
const DocContext = require('./../../doc-context.js');


/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        let today = new Date;

        this.onClickHandler = this.onClickHandler.bind(this);
        this.handleClick = this.handleClick.bind(this);
        this.renderer = this.renderer.bind(this);
        this.modalReportePageBtnClick = this.modalReportePageBtnClick.bind(this);

        this.state = {
            read: 0,
            filtri_read: 0,
            isReport: false,
            txtReport: [],
            kehtivus: today
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
                                  style={styles}
                                  render={this.renderer}/>
                <InputText title="Filtri all / read kokku:"
                           name='read_kokku'
                           style={styles.total}
                           ref="input-read"
                           value={String(this.state.filtri_read + '/' + this.state.read)}
                           disabled={true}/>
                <ModalReport
                    show={this.state.isReport}
                    report={this.state.txtReport}
                    modalPageBtnClick={this.modalReportePageBtnClick}>
                </ModalReport>
            </div>
        );
    }

    renderer(self) {
        if (!self) {
            // не инициализировано
            return null;
        }

        let docRights = DocRights[DOC_TYPE_ID] ? DocRights[DOC_TYPE_ID] : [];
        let userRoles = DocContext.userData ? DocContext.userData.roles : [];

        let events = EVENTS.filter(event => {
            // только доступные таски должны попасть в список
            let kas_lubatud = checkRights(userRoles, docRights, event.method);
            return kas_lubatud;
        });

        if (self.gridData) {
            this.setState({
                read: self.gridData && self.gridData.length && self.gridData[0].rows_total ? self.gridData[0].rows_total : this.state.read,
                filtri_read: self.gridData && self.gridData.length && self.gridData[0].filter_total ? self.gridData[0].filter_total : 0
            });
        }

        return (
            <ToolbarContainer>
                {checkRights(userRoles, docRights, 'arvestaTaabel') ?
                    events.map(event => {
                        return (
                            <BtnArvesta
                                value={event.name}
                                onClick={this.onClickHandler}
                                ref={`btn-${event.name}`}
                                key={`key-${event.name}`}
                            />
                        )
                    }) : null}
                {checkRights(userRoles, docRights, 'importLapsed') ?
                    <ButtonUpload
                        ref='btnUpload'
                        docTypeId={DOC_TYPE_ID}
                        onClick={this.handleClick}
                        show={true}
                        value={'Import lapsed'}
                        mimeTypes={'.csv'}
                    /> : null}
                {checkRights(userRoles, docRights, 'importViitenr') ?
                    <ButtonUpload
                        ref='btnUpload'
                        docTypeId={'VIITENR'}
                        onClick={this.handleClick}
                        show={true}
                        value={'Import viitenumbrid'}
                        mimeTypes={'.csv'}
                    /> : null}

            </ToolbarContainer>
        )
    }

    onClickHandler(event, seisuga) {
        const Doc = this.refs['register'];

        // собираем параметры
        const ids = [];
        Doc.gridData.filter(row => row.select).forEach(row => {
            ids.push(row.id);
        });


        const task = EVENTS.find(task => task.name === event);
        if (!task) {
            return Doc.setState({warning: `Task: ${event} ei leidnud`, warningType: 'error'});
        }

        // отправляем запрос на выполнение
        let message = `võib olla selles perioodil kõik arved juba väljastatud`;
        Doc.fetchData(`calc/${task.method}`, {docs: ids, seisuga: seisuga}).then((data) => {
            if (data.result) {
                message = `task saadetud täitmisele`;
                Doc.setState({warning: `${message}`, warningType: 'ok'});

                let tulemused = data.data.result.tulemused;
                // открываем отчет
                this.setState({isReport: true, txtReport: tulemused});

            } else {
                if (data.error_message) {
                    Doc.setState({warning: `Tekkis viga: ${data.error_message}`, warningType: 'error'});
                } else {
                    Doc.setState({
                        warning: `Kokku arvestatud : ${data.result}, ${message}`,
                        warningType: 'notValid'
                    });
                }

            }

        });
    }


    /**
     * кастомный обработчик события клик на кнопку импорта
     */
    handleClick(result) {

        //обновим данные
        const Doc = this.refs['register'];
        if (!Doc) {
            return null;
        }
        if (result) {
            Doc.setState({warning: `Edukalt:  ${result}: `, warningType: 'ok'});
            setTimeout(() => {
                Doc.fetchData('selectDocs');
            }, 10000);
        }
    }

    /**
     * уберет окно с отчетом
     */
    modalReportePageBtnClick(event) {
        let isReport = event && event == 'Ok' ? false : true;
        this.setState({isReport: isReport})
    }

}


module.exports = (Documents);

