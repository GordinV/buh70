'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    flux = require('fluxify'),
    ToolbarContainer = require('./../toolbar-container/toolbar-container.jsx'),
    BtnAdd = require('./../button-register/button-register-add/button-register-add.jsx'),
    BtnEdit = require('./../button-register/button-register-edit/button-register-edit.jsx'),
    BtnSave = require('./../button-register/button-register-save/button-register-save.jsx'),
    BtnCancel = require('./../button-register/button-register-cancel/button-register-cancel.jsx'),
    BtnPrint = require('./../button-register/button-register-print/button-register-print.jsx'),
    TaskWidget = require('./../task-widget/task-widget.jsx');

class DocToolBar extends React.PureComponent {
    constructor(props) {
        super(props);

        this.btnEditClick = this.btnEditClick.bind(this);
        this.btnAddClick = this.btnAddClick.bind(this);
        this.btnSaveClick = this.btnSaveClick.bind(this);
        this.btnCancelClick = this.btnCancelClick.bind(this);
        this.btnPrintClick = this.btnPrintClick.bind(this);
        this.handleButtonTask = this.handleButtonTask.bind(this);
        this.handleSelectTask = this.handleSelectTask.bind(this);

        this.docId = null;

        if (props.docId) {
            this.docId = props.docId
        } else {
            this.docId = flux.stores.docStore ? flux.stores.docStore.data.id:  0;
        }
    }

    render() {
        let isEditMode = this.props.edited,
            isDocDisabled = this.props.docStatus == 2,
            docId = this.docId,
            toolbarParams = {
                btnAdd: {
                    show: !isEditMode,
                    disabled: isEditMode
                },
                btnEdit: {
                    show: !isEditMode,
                    disabled: isDocDisabled
                },
                btnPrint: {
                    show: true,
                    disabled: true
                },
                btnSave: {
                    show: isEditMode,
                    disabled: false
                },
                btnCancel: {
                    show: isEditMode && docId !==0,
                    disabled: false
                }
            };

        return <ToolbarContainer ref='toolbarContainer'>
            <div>
                <BtnAdd ref='btnAdd' onClick={this.btnAddClick} show={toolbarParams['btnAdd'].show}
                        disabled={toolbarParams['btnAdd'].disabled}/>
                <BtnEdit ref='btnEdit' onClick={this.btnEditClick} show={toolbarParams['btnEdit'].show}
                         disabled={toolbarParams['btnEdit'].disabled}/>
                <BtnSave ref='btnSave' onClick={this.btnSaveClick} show={toolbarParams['btnSave'].show}
                         disabled={toolbarParams['btnSave'].disabled}/>
                <BtnCancel ref='btnCancel' onClick={this.btnCancelClick} show={toolbarParams['btnCancel'].show}
                           disabled={toolbarParams['btnCancel'].disabled}/>
                <BtnPrint ref='btnPrint' onClick={this.btnPrintClick} show={toolbarParams['btnPrint'].show}
                          disabled={toolbarParams['btnPrint'].disabled}/>
                {this.props.bpm.length ? <TaskWidget ref='taskWidget'
                                              taskList={this.props.bpm}
                                              handleSelectTask={this.handleSelectTask}
                                              handleButtonTask={this.handleButtonTask}
                    /> : null}

            </div>
        </ToolbarContainer>
    }

    /**
     * Вызовет метод перехода на новый документ
     */
    btnAddClick() {
        if (!this.props.btnAddClick) {
            flux.doAction('editedChange', true);
            flux.doAction('savedChange', false);
            flux.doAction('addDoc');
        } else {
            this.props.btnAddClick();
        }
    }

    /**
     * обработчик для кнопки Edit
     */
    btnEditClick() {
        // переводим документ в режим редактирования, сохранен = false
        if (!this.props.docStatus || this.props.docStatus < 2) {
            if (!this.props.btnEditClick) {
                flux.doAction('editedChange', true);
                flux.doAction('savedChange', false);
            } else {
                this.props.btnEditClick();
            }
        }
    }

    btnPrintClick() {
        console.log('print called');
        if (this.props.btnPrintClick) {
            this.props.btnPrintClick();
        }
    }

    /**
     * обработчик для кнопки Save
     */
    btnSaveClick() {
        // валидатор
        let validationMessage = this.props.validator ? this.props.validator() : '',
            isValid = this.props.validator ? !validationMessage : true;

        if (isValid) {
            // если прошли валидацию, то сохранеям
            if (this.props.btnSaveClick) {
                this.props.btnSaveClick();
            } else {
                flux.doAction('saveData');
                flux.doAction('editedChange', false);
                flux.doAction('savedChange', true);
            }

        }
    }

    /**
     * Обработчик для события клика для кнопки Отказ
     */
    btnCancelClick() {
        if (this.props.btnCancelClick) {
            this.props.btnCancelClick()
        } else {
            // обработчик для кнопки Cancel
            if (this.props.eventHandler) {
                this.props.eventHandler('CANCEL');
            }

            flux.doAction('editedChange', false);
            flux.doAction('savedChange', true);
        }
    }

    handleButtonTask(task) {
        // метод вызывается при выборе задачи
        //@todo Закончить

        flux.doAction('executeTask', task);
    }


    handleSelectTask(e) {
        // метод вызывается при выборе задачи
        //@todo Закончить
        const taskValue = e.target.value;
    }

}

DocToolBar.propTypes = {
    bpm: PropTypes.array,
    edited: PropTypes.bool,
    docStatus: PropTypes.number,
    validator: PropTypes.func
};

DocToolBar.defaultProps = {
    bpm: [],
    edited: false,
    docStatus: 0
};

module.exports = DocToolBar;