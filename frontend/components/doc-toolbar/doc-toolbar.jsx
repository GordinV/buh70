'use strict';

const PropTypes = require('prop-types');
//const {withRouter} = require('react-router-dom');

const React = require('react'),
    ToolbarContainer = require('./../toolbar-container/toolbar-container.jsx'),
    BtnAdd = require('./../button-register/button-register-add/button-register-add.jsx'),
    BtnEdit = require('./../button-register/button-register-edit/button-register-edit.jsx'),
    BtnSave = require('./../button-register/button-register-save/button-register-save.jsx'),
    BtnCancel = require('./../button-register/button-register-cancel/button-register-cancel.jsx'),
    BtnPrint = require('./../button-register/button-register-print/button-register-print.jsx'),
    BtnEmail = require('./../button-register/button-email/index.jsx'),
    BtnLogs = require('./../show-logs/index.jsx'),
    TaskWidget = require('./../task-widget/task-widget.jsx');

class DocToolBar extends React.PureComponent {
    constructor(props) {
        super(props);

        this.btnEditClick = this.btnEditClick.bind(this);
        this.btnAddClick = this.btnAddClick.bind(this);
        this.btnSaveClick = this.btnSaveClick.bind(this);
        this.btnCancelClick = this.btnCancelClick.bind(this);
        this.btnPrintClick = this.btnPrintClick.bind(this);
        this.btnEmailClick = this.btnEmailClick.bind(this);
        this.btnLogsClick = this.btnLogsClick.bind(this);
        this.handleButtonTask = this.handleButtonTask.bind(this);
        this.handleSelectTask = this.handleSelectTask.bind(this);

        this.docId = null;

        if (props.docId) {
            this.docId = props.docId
        }
    }

    render() {
        let isEditMode = this.props.edited,
            isDocDisabled = this.props.docStatus === 2 ,
            docId = this.docId,
            toolbarParams = {
                btnAdd: {
                    show: !isEditMode,
                    disabled: isEditMode
                },
                btnEdit: {
                    show: !isEditMode && !isDocDisabled,
                    disabled: isDocDisabled
                },
                btnPrint: {
                    show: true,
                    disabled: false
                },
                btnEmail: {
                    show: true,
                    disabled: false
                },
                btnSave: {
                    show: isEditMode && !isDocDisabled,
                    disabled: false
                },
                btnCancel: {
                    show: isEditMode && docId !== 0,
                    disabled: false
                }
            };

        return <ToolbarContainer ref='toolbarContainer'>
            <BtnAdd ref='btnAdd' onClick={this.btnAddClick} show={toolbarParams['btnAdd'].show}
                    disabled={toolbarParams['btnAdd'].disabled}/>
            <BtnEdit ref='btnEdit'
                     value={'Muuda'}
                     onClick={this.btnEditClick}
                     show={toolbarParams['btnEdit'].show}
                     disabled={toolbarParams['btnEdit'].disabled}/>
            <BtnSave ref='btnSave'
                     value={'Salvesta'}
                     onClick={this.btnSaveClick}
                     show={toolbarParams['btnSave'].show}
                     disabled={toolbarParams['btnSave'].disabled}/>
            <BtnCancel ref='btnCancel'
                       value={'Tühista'}
                       onClick={this.btnCancelClick}
                       show={toolbarParams['btnCancel'].show}
                       disabled={toolbarParams['btnCancel'].disabled}/>
            <BtnPrint ref='btnPrint'
                      value={'Trükk'}
                      onClick={this.btnPrintClick}
                      show={toolbarParams['btnPrint'].show}
                      disabled={toolbarParams['btnPrint'].disabled}/>
            <BtnEmail ref='btnEmail'
                      docTypeId={this.props.docTypeId}
                      onClick={this.btnEmailClick}
                      show={toolbarParams['btnEmail'].show}
                      disabled={toolbarParams['btnEmail'].disabled}/>
            <BtnLogs ref='btnLogs'
                     data={this.props.logs}
                     onClick={this.btnLogsClick}
                     show={!isEditMode}/>
            {(this.props.bpm.length && !isDocDisabled && !isEditMode) ? <TaskWidget ref='taskWidget'
                                                                     taskList={this.props.bpm}
                                                                     handleSelectTask={this.handleSelectTask}
                                                                     handleButtonTask={this.handleButtonTask}
            /> : null}
        </ToolbarContainer>
    }

    /**
     * Вызовет метод перехода на новый документ
     */
    btnAddClick() {
        if (this.props.btnAddClick) {
            this.props.btnAddClick();
        } else {
            console.error('method add not exists in props')
        }
    }

    /**
     * обработчик для кнопки Edit
     */
    btnEditClick() {
        // переводим документ в режим редактирования, сохранен = false
        if (!this.props.docStatus || this.props.docStatus < 2) {
            //this.docId
            if (this.props.history) {
                return this.props.history.push(`/raama/${value}`)
            }

            if (this.props.btnEditClick) {
                this.props.btnEditClick();
            } else {
                console.error('method edit not exists in props')

            }
        }
    }

    btnPrintClick() {
        if (this.props.btnPrintClick) {
            this.props.btnPrintClick();
        }
    }

    /**
     * обработчик для кнопки email
     */
    btnEmailClick() {
        if (this.props.btnEmailClick) {
            this.props.btnEmailClick();
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
                console.error('method save not exists in props')
            }
        } else {
            console.log('Document is not valid', isValid);
        }
    }

    /**
     * Обработчик для события клика для кнопки Отказ
     */
    btnCancelClick() {
        if (this.props.btnCancelClick) {
            this.props.btnCancelClick()
        } else {
            console.error('method cancel not exists in props')
        }
    }

    btnLogsClick() {
        if (this.props.btnLogsClick) {
            this.props.btnLogsClick();
        }
    }

    handleButtonTask(taskName, kpv) {
        // ишем таску
        const task = this.props.bpm.find(row => row.name === taskName);

        if (task) {
            // метод вызывается при выборе задачи
            if (this.props.btnTaskClick) {
                return this.props.btnTaskClick(task.name, kpv);
            }

        }

    }

    handleSelectTask(e) {
        // метод вызывается при выборе задачи
        const taskValue = e.target.value;
        if (this.props.btnTaskClick) {
            return this.props.btnTaskClick(taskValue)
        }

    }

}

DocToolBar.propTypes = {
    bpm: PropTypes.array,
    docTypeId: PropTypes.text,
    edited: PropTypes.bool,
    docStatus: PropTypes.number,
    validator: PropTypes.func
};

DocToolBar.defaultProps = {
    bpm: [],
    edited: false,
    docStatus: 0
};

//module.exports = withRouter(DocToolBar);
module.exports = DocToolBar;