'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const BtnArvesta = require('./../../components/button-register/button-task/index.jsx');
const ButtonUpload = require('./../../components/upload_button/index.jsx');
const InputNumber = require('../../components/input-number/input-number.jsx');

const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');

const styles = require('./laps-register-styles');
const DOC_TYPE_ID = 'LAPS';
const EVENTS = [
    {name: 'Tabeli koostamine', method: 'arvestaTaabel', docTypeId: 'lapse_taabel'},
    {name: 'Arve koostamine', method: 'koostaArve', docTypeId: 'arv'},
    {name: 'Ettemaksuarve koostamine', method: 'koostaEttemaksuArved', docTypeId: 'arv'},
];

const DocRights = require('./../../../config/doc_rights');
const checkRights = require('./../../../libs/checkRights');
const DocContext = require('./../../doc-context.js');


/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.onClickHandler = this.onClickHandler.bind(this);
        this.handleClick = this.handleClick.bind(this);
        this.renderer = this.renderer.bind(this);
        this.state = {
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
                                  style={styles}
                                  render={this.renderer}/>
                <InputNumber title="Read kokku:"
                             name='read_kokku'
                             style={styles.total}
                             ref="input-read"
                             value={Number(this.state.read) || 0}
                             disabled={true}/>
            </div>
        );
    }

    renderer(self) {
        let docRights = DocRights['LAPS'] ? DocRights['LAPS'] : [];
        let userRoles = DocContext.userData ? DocContext.userData.roles : [];

        let events = EVENTS.filter(event => {
            // только доступные таски должны попасть в список
            let kas_lubatud = checkRights(userRoles, docRights, event.method);
            return kas_lubatud;
        });

        if (self.gridData) {
            this.setState({read: self.gridData.length});
        }

        return (
            <ToolbarContainer>
                {events.map(event => {
                    return (
                        <BtnArvesta
                            value={event.name}
                            onClick={this.onClickHandler}
                            ref={`btn-${event.name}`}
                            key={`key-${event.name}`}
                        />

                    )
                })}
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
                if (task.method == 'koostaEttemaksuArved') {
                    message = `task saadetud täitmisele`;
                } else {
                    message = `Kokku arvestatud: ${data.result}, suunatamine...`;
                }

                Doc.setState({warning: `${message}, suunatamine...`, warningType: 'ok'});

                // ждем 10 сек и редайрект на табеля
                setTimeout(() => {
                    this.props.history.push(`/lapsed/${task.docTypeId}`);
                }, 1000 * 5);
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
}


module.exports = (Documents);

