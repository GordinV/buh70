'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const BtnArvesta = require('./../../components/button-register/button-task/index.jsx');
const ButtonUpload = require('./../../components/upload_button/index.jsx');

const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');

const styles = require('./laps-register-styles');
const DOC_TYPE_ID = 'LAPS';
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
        this.handleClick = this.handleClick.bind(this);
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
                {EVENTS.map(event => {
                    return (
                        <BtnArvesta
                            value={event.name}
                            onClick={this.onClickHandler}
                            ref={`btn-${event.name}`}
                        />

                    )
                })}
                <ButtonUpload
                    ref='btnUpload'
                    docTypeId={DOC_TYPE_ID}
                    onClick={this.handleClick}
                    show={true}
                />

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
        Doc.fetchData(`calc/${task.method}`, {docs:ids, seisuga:seisuga}).then((data) => {
            if (data.result) {
                Doc.setState({warning: `Kokku arvestatud: ${data.result}, suunatamine...`, warningType: 'ok'});

                // ждем 10 сек и редайрект на табеля
                setTimeout(() => {
                    this.props.history.push(`/lapsed/${task.docTypeId}`);
                }, 1000 * 5);
            } else {
                if (data.error_message) {
                    Doc.setState({warning: `Tekkis viga: ${data.error_message}`, warningType: 'error'});
                } else  {
                    Doc.setState({warning: `Kokku arvestatud : ${data.result}, võib olla selles perioodil kõik arved juba väljastatud`, warningType: 'notValid'});
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

        Doc.setState({warning:`Edukalt:  ${result}: `, warningType:'ok'});
        setTimeout(() => {
            Doc.fetchData('selectDocs');
        }, 10000);
    }
}


module.exports = (Documents);

