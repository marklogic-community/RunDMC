/* jshint esversion:6 */

Vue.component('search', {
  props: ['page', 'criteria'],
  data: function() {
    return {

    };
  },
  template:
    `<div class="input-group">
       <input type="text" class="form-control" placeholder="Search recipes"/>
       <span class="input-group-btn">
         <button class="btn btn-default" type="button">Go!</button>
       </span>
     </div>`,
  watch: {
    page: function(newPage) {
      this.runSearch();
    },
    criteria: function(newCriteria) {
      console.log('new criteria: ' + JSON.stringify(newCriteria));
      this.runSearch();
    }
  },
  methods: {
    runSearch: function() {
      let vm = this;
      var oReq = new XMLHttpRequest();
      oReq.onload = function (e) {
        let json = JSON.parse(this.response);
        vm.$emit('searchResults', json);
      };
      let queryString = '?p=' + this.page;
      if (this.criteria.tag) {
        queryString += '&tag=' + this.criteria.tag;
      }
      oReq.open('GET', '/service/recipe-search' + queryString, true);
      oReq.send();

    }
  }
});

Vue.component('pagination', {
  props: ['pages', 'current'],
  template:
    `<nav aria-label="Page navigation">
      <ul class="pagination">
        <li v-bind:class="{disabled: current === 1 }">
          <span aria-hidden="true" v-on:click="decrement">&laquo;</span>
        </li>
        <li v-for="page in pages" v-bind:class="{active: page === current }">
          <span v-on:click="setPage">{{ page }}</span>
        </li>
        <li v-bind:class="{disabled: current === pages }">
          <span aria-hidden="true" v-on:click="increment">&raquo;</span>
        </li>
      </ul>
    </nav>`,
    methods: {
      decrement: function() {
        this.$emit('setPage', this.current - 1);
      },
      increment: function() {
        this.$emit('setPage', this.current + 1);
      },
      setPage: function(event) {
        this.$emit('setPage', Number(event.currentTarget.textContent));
      }
    }
});

Vue.component('recipes', {
  props: [''],
  data: function() {
    return {
      current: 0,
      total: 0,
      pages: 0,
      start: 0,
      end: 0,
      recipes: [],
      searchCriteria: {}
    };
  },
  template:
    `<div>
      <div class="row">

        <div class="col-md-8">
          A recipe provides a reusable solution to a common problem. While a design pattern gives you an approach to solving a problem, a recipe will be pretty close to a copy &amp; paste solution.
        </div>

        <div class="col-md-4">
          <search v-bind:page="current" v-on:searchResults="updateResults"
            v-bind:criteria="searchCriteria"/>
        </div>

      </div>
      <pagination
        v-bind:pages="pages" v-bind:current="current"
        v-on:setPage="setPage"></pagination>
      <ul class="recipes list-unstyled">
        <li v-for="recipe in recipes">
          <recipe v-bind:title="recipe.title" v-bind:url="recipe.url" v-bind:problem="recipe.problem"
            v-bind:min="recipe.minVersion" v-bind:max="recipe.maxVersion" v-bind:tags="recipe.tags"
            v-on:searchCriteria="updateSearchCriteria"
            ></recipe>
        </li>
      </ul>
     </div>`,
  methods: {
    setPage: function(page) {
      this.current = page;
    },
    updateResults: function(results) {
      this.total = results.total;
      this.pages = results.pages;
      this.start = results.start;
      this.end = results.end;
      this.recipes = results.recipes;
    },
    updateSearchCriteria: function(criteria) {
      this.currentTarget = 1;
      this.searchCriteria = criteria;
    }
  },
  mounted: function() {
    this.current = 1;
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
      <button v-for="tag in tags" class="btn btn-default btn-xs" v-on:click="onTagClick">{{tag}}</button>
      <p>{{problem}}</p>
      <em>Applies to MarkLogic versions {{min}}<span v-if="max === ''">+</span>
        <span v-else> to {{max}}</span>
      </em>
    </div>`,
  methods: {
    onTagClick: function(event) {
      this.$emit('searchCriteria', { tag: event.currentTarget.textContent });
    }
  }
});

var recipe = new Vue({
  el: '#recipe',
  data: {
  },
  methods: {
  }
});
