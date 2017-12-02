'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    flux = require('fluxify');

const
    Form = require('../../components/form/form.jsx'),
    InputText = require('../../components/input-text/input-text.jsx'),
    TextArea = require('../../components/text-area/text-area.jsx'),
    ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx'),
    DocToolBar = require('./../../components/doc-toolbar/doc-toolbar.jsx'),
    MenuToolBar = require('./../../mixin/menuToolBar.jsx'),
    validateForm = require('../../mixin/validateForm'),
    styles = require('./project-styles');

// Create a store
const docStore = require('../../stores/doc_store.js');

class Project extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            edited: props.data.row.id == 0,
            warning: ''
        };

        this.docData = props.data.row;

        this.requiredFields = [
            {
                name: 'kood',
                type: 'C',
                min: null,
                max: null
            },
            {name: 'nimetus', type: 'C', min: null, max: null},
            {name: 'regkood', type: 'C', min: null, max: null}
        ];
        this.handleToolbarEvents = this.handleToolbarEvents.bind(this);
        this.validation = this.validation.bind(this);
        this.handleInputChange = this.handleInputChange.bind(this);
//        this.prepaireToolBarParameters = this.prepaireToolBarParameters.bind(this);
    }

    /**
     * вызовет метод валидации и вернет результат проверки
     * @returns {string}
     */
    validation() {
        if (!this.state.edited) return '';

        let requiredFields = this.requiredFields;
        return require('../../mixin/validateForm')(this, requiredFields);
    }

    componentDidMount() {
        // пишем исходные данные в хранилище, регистрируем обработчики событий
        let self = this,
            data = this.docData;

        window.addEventListener('beforeunload', this.componentCleanup);

        // сохраняем данные в хранилище
        flux.doAction('dataChange', data);

        // если новый документ (id == 0)

        if (data.id == 0) {
            flux.doAction('editedChange', true);
            flux.doAction('savedChange', false);
        }

        // отслеживаем режим редактирования
        docStore.on('change:edited', function (newValue, previousValue) {
            if (newValue !== previousValue) {
                self.setState({edited: newValue});
            }
        });

    }

    /**
     * снимет все подписки
     */
    componentCleanup() {
        docStore.off('change:edited');
    }

    render() {
        let isEditeMode = this.state.edited,
            validationMessage = this.validation();
        const btnParams = {
            btnStart: {
                show: true
            }
        };

        return (
            <div>
                {MenuToolBar(btnParams, this.props.userData)}

                <Form pages={this.pages}
                      ref="form"
                      handlePageClick={this.handlePageClick}
                      disabled={isEditeMode}>
                    <ToolbarContainer ref='toolbar-container'>
                        <div className='doc-toolbar-warning'>
                            {validationMessage ? <span>{validationMessage}</span> : null }
                        </div>
                        <div>
                            <DocToolBar ref='doc-toolbar'
                                        edited={isEditeMode}
                                        validator={this.validation}
                                        eventHandler={this.handleToolbarEvents}/>
                        </div>
                    </ToolbarContainer>
                    <div style={styles.doc}>
                        <div style={styles.docRow}>
                            <InputText title="Kood "
                                       name='kood'
                                       ref="input-kood"
                                       value={this.docData.kood}
                                       onChange={this.handleInputChange}/>
                        </div>
                        <div style={styles.docRow}>
                            <InputText title="Nimetus "
                                       name='nimetus'
                                       ref="input-nimetus"
                                       value={this.docData.nimetus}
                                       onChange={this.handleInputChange}/>
                        </div>

                        <div style={styles.docRow}>
                                <TextArea title="Muud"
                                          name='muud'
                                          ref="textarea-muud"
                                          onChange={this.handleInputChange}
                                          value={this.docData.muud || ''}
                                          readOnly={!isEditeMode}/>
                        </div>
                    </div>
                </Form >
            </div>
        );
    }

    /**
     * Обработчик для панели сохранения
     * @param event
     */
    handleToolbarEvents(event) {
        // toolbar event handler

        switch (event) {
            case 'CANCEL':
                this.docData = JSON.parse(flux.stores.docStore.backup.docData); // восстановим данные

                if (this.state.warning !== '') {
                    this.setState({warning: ''});
                } else {
                    this.forceUpdate();
                }
                break;
            default:
                console.error('handleToolbarEvents, no event handler for ', event);
        }
    }

    /**
     * Обработчик для инпутов.
     * @param inputName
     * @param inputValue
     * @returns {boolean}
     */
    handleInputChange(inputName, inputValue) {
        // обработчик изменений
        // изменения допустимы только в режиме редактирования
        if (!this.state.edited) {
            console.error('not in edite mode');
            return false;
        }

        this.docData[inputName] = inputValue;
        this.forceUpdate();
    }

    /**
     * Подготовит параметры для панетли инструментов
     * @param isEditMode
     * @returns {{btnAdd: {show: boolean, disabled: *}, btnEdit: {show: boolean, disabled: *}, btnPrint: {show: boolean, disabled: boolean}, btnSave: {show: *, disabled: boolean}}}
     */
    static prepaireToolBarParameters(isEditMode) {
        return  {
            btnAdd: {
                show: !isEditMode,
                disabled: isEditMode
            },
            btnEdit: {
                show: !isEditMode,
                disabled: isEditMode
            },
            btnPrint: {
                show: true,
                disabled: true
            },
            btnSave: {
                show: isEditMode,
                disabled: false
            }
        };
    }

}


Project.propTypes = {
    data: PropTypes.object.isRequired,
    edited: PropTypes.bool,
    warning: PropTypes.string

};

module.exports = Project;


