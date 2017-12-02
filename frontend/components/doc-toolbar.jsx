'use strict';

const DOCUMENT_CLOSED_STATUS = 2;

const React = require('react'),
    DocButton = require('./doc-button.jsx'),
    flux = require('fluxify');

var Toolbar = React.createClass({
    getInitialState: function () {
        return {
            warning: false, warningMessage: '', editMode: false,
            taskList: this.props.taskList ? this.props.taskList : this.getDefaultTask()
        }
    },

    componentWillMount: function () {
// создаем обработчик события на изменение docId. Если значение = 0 (добавляем новую запись, то просто очитка полей, иначе подгрузка данных
        var self = this;

        flux.stores.docStore.on('change:saved', function (newValue, previousValue) {
            if (newValue !== previousValue) {
                // режим изменился, меняем состояние
                self.setState({editMode: !newValue});
            }
        });

    },

    handleSelectTask: function (e) {
        // метод вызывается при выборе задачи
        var taskValue = e.target.value;
    },

    handleButtonTask: function () {
        // метод вызывается при выборе задачи
        // найдем актуальную задачу

        let actualTask = this.state.taskList.filter((task)=> {
                if (task.actualStep) {
                    return task;
                }
            }),
            task = actualTask.map((task) => {
                return task.action
            }); // оставим только название процедуры

        flux.doAction('executeTask', task);
    },

    handleEventButtonAddClick() {
        // обработчик для кнопки Add
            // отправим извещение наверх
//        this.props.onClick(this.name);
            flux.doAction( 'docIdChange', 0 );
            flux.doAction( 'editedChange', true );
            flux.doAction( 'savedChange', false );
        },

    handleEventButtonEditClick() {
        // обработчик для кнопки Edit
        // переводим документ в режим редактирования, сохранен = false
        flux.doAction( 'editedChange', true );
        flux.doAction( 'savedChange', false );

    },

    handleEventButtonSaveClick() {
        // обработчик для кнопки Save
        // валидатор

        let isValid = !this.validator();

        if (isValid) {
            // если прошли валидацию, то сохранеям
            flux.doAction( 'saveData');
        }
    },

    render: function () {
        let editeMode = this.state.editMode,
            documentStatus = this.props.documentStatus,
            isClosedStatus = documentStatus == DOCUMENT_CLOSED_STATUS ? true : false,
            taskWidget = this.generateTaskWidget(),
            tasks = this.state.taskList.map((task) => {
                return task.action
            });

        return (
            <div>
                <div className='doc-toolbar-warning'>
                    {this.state.warning ? <span>{this.state.warningMessage}</span> : null }
                </div>
                <div className='doc-toolbar' style={{float:"right"}}>
                    {isClosedStatus ? null : <DocButton
                        value='Add'
                        className='doc-toolbar'
                        enabled={this.state.editMode}
                        onClick={this.handleEventButtonAddClick}/>}
                    {isClosedStatus ? null : <DocButton
                        value='Edit'
                        enabled={this.state.editMode}
                        onClick={this.handleEventButtonEditClick}
                        className='doc-toolbar'/>}
                    {isClosedStatus ? null : <DocButton
                            className='doc-toolbar'
                            value = "Save"
                            enabled={!this.state.editMode}
                            onClick={this.handleEventButtonSaveClick}/>}
                    {editeMode && tasks.length > 0 ? null : taskWidget}
                </div>
            </div>
        );
    },

    getDefaultTask: function () {
        return [{step: 0, name: 'Start', action: 'start', status: 'opened'}]

    },

    generateTaskWidget: function () {
        // вернет виджет задач

        if (!this.state.taskList) {
            this.setState({taskList: this.getDefaultTask()});
        }

        let tasks = this.state.taskList.filter(task => {

                if (task.status === 'opened') {
                    return task;
                }
            }),

            options,
            taskWidget = null;

        if (tasks.length > 1) {
            // формируем список задач
            options = tasks.map((task) => {
                return <option value={0} key={Math.random()}> {task.name} </option>
            });

            taskWidget = <select className='ui-c2' onChange={this.handleSelectTask}>{options} </select>
        }

        if (tasks.length == 1) {
            var taskName = tasks[0].name;
            // кнопка с задачей
            taskWidget = <input type="button" className='ui-c2' onClick={this.handleButtonTask} value={taskName}/>
        }
        return taskWidget;
    },


    validator: function () {
        let warning = '';

        if (this.props.validator) {
            let warningMessage = this.props.validator();
                warning = warningMessage !== 'Ok'

            this.setState({warningMessage: warningMessage, warning: warning})
        }
        return warning;
    }
});

module.exports = Toolbar;


