/* jshint esversion:6 */

Vue.component('recipes', {
  props: [''],
  data: function() {
    return {
      recipes: [
        {
          'title': 'Get permissions with role names',
          'url': '/recipe/get-permissions-with-role-names',
          'problem': 'Get the permissions on a document, decorated with the names of the roles.',
          'minVersion': '7',
          'maxVersion': '9',
          'tags': ['permissions', 'security', 'xquery', 'query console']
        },
        {
          'title': 'Current and effective MarkLogic versions during rolling upgrade',
          'url': '/recipe/rolling-upgrade-versions',
          'problem': 'During a rolling upgrade, some servers will have the original version, while others will have the new version but act as if they still had the old. Generate a report showing which servers have which actual and effective versions.',
          'minVersion': '8.0-7',
          'maxVersion': '',
          'tags': ['xquery', 'rolling upgrade', 'administration', 'query console']
        }
      ]
    };
  },
  template:
    `<ul class="list-unstyled">
       <li v-for="recipe in recipes">
         <recipe v-bind:title="recipe.title" v-bind:url="recipe.url" v-bind:problem="recipe.problem"
           v-bind:min="recipe.minVersion" v-bind:max="recipe.maxVersion" v-bind:tags="recipe.tags"></recipe>
       </li>
     </ul>`,
  mounted: function() {
    $.ajax({
      'method': 'GET',
      'url': ''
    });
  }
});

Vue.component('recipe', {
  props: ['title', 'url', 'problem', 'min', 'max', 'tags'],
  data: function () {
    return {
    };
  },
  template:
    `<div class="recipe">
      <h4><a v-bind:href="url">{{title}}</a></h4>
      <button v-for="tag in tags" class="btn btn-default btn-xs">{{tag}}</button>
      <p>{{problem}}</p>
      <em>Applies to MarkLogic versions {{min}}<span v-if="max === ''">+</span>
        <span v-else> to {{max}}</span>

      </em>
    </div>`
});

var recipe = new Vue({
  el: '#recipe',
  data: {
  }
});
