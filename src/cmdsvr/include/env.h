#ifndef _UTIL_ENV_H
#define _UTIL_ENV_H

#include "util_def.h"

#include <string.h>
#include <stdlib.h>

static inline int util_env_parse_int(const char *env_name,
		int default_value)
{
	char *env_value_str = getenv(env_name);
	char *tail_ptr = NULL;
	int env_value;

	if (!env_value_str) {
		return default_value;
	}
	env_value = strtol(env_value_str, &tail_ptr, 0);
	if (env_value == 0 && env_value_str == tail_ptr) {
		return default_value;
	}

	return env_value;
}

static inline float util_env_parse_float(const char *env_name,
		float default_value)
{
	char *env_value_str = getenv(env_name);
	char *tail_ptr = NULL;
	float env_value;

	if (!env_value_str) {
		return default_value;
	}
	env_value = strtof(env_value_str, &tail_ptr);
	if (env_value == 0.0 && env_value_str == tail_ptr) {
		return default_value;
	}

	return env_value;
}

static inline char *util_env_parse_str(const char *env_name,
		char *default_value)
{
	char *env_value_str = getenv(env_name);

	if (!env_value_str)
		return default_value;

	return strdup(env_value_str);
}

#endif /* _UTIL_ENV_H */
