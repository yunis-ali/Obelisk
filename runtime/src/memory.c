#include "object.h"
#include "memory.h"
#include "oberror.h"

#include <stdlib.h>

/* Resize a memory area */
void * resize_pointer(size_t size, void * old)
{
   /* Our new pointer */
   void * new;
   
   /* Try to resize the pointer */
   new = realloc(old, size);

   if (new == NULL)
   {
      FATAL_ERROR("Ran out of memory!");
   }

   return new;
}

/* Request a new pointer from the operating system */
void * new_pointer(size_t size)
{
   /* Our new pointer */
   void * ptr;

   /* Try to create a new pointer */
   ptr = malloc(size);

   /* If the pointer is NULL, raise an error and abort execution! */
   if (ptr == NULL)
   {
      FATAL_ERROR("Ran out of memory!");
   }
   
   return ptr;
}

/* Create a new chunk */
chunk_addr new_chunk(size_t size, memory_manager mem)
{
   /* The address of the chunk we are going to return! */
   chunk_addr zone;

   /* Request a pointer from the operating system */
   zone = (chunk_addr) new_pointer(sizeof(zone));

   /* Write the address of the new chunk to chnk pointer */
   *zone = mem->next;

   /* Initialize the chunk */
   mem->next->size = size;
   mem->next->addr = zone;

   /* Set the next chunk pointer to be after the address of chnk chunk */
   mem->next = (chunk *) ((word *) mem->next + chunk_size(size));

   /* Return the address */
   return zone;
}

/* Is there enough space to make a new chunk of the given size? */
int enough_space(size_t size, memory_manager mem)
{
   return ((int) mem->next + chunk_size(size)) - (int) mem->current < (int) mem->size;
}

/* Allocate a new chunk */
chunk_addr allocate(size_t size, memory_manager mem)
{
   /* If there is not enough free space for the new chunk */
   if (! enough_space(size, mem))
   {
      grow(size, mem);
   }

   /* Return the new chunk */
   return new_chunk(size, mem);
}

/* Grow memory.  Double in size, or increase by at least as much space as 'at_least'. */
void grow(size_t at_least, memory_manager mem)
{
   /* The size of currently used memory */
   size_t used;

   /* The miniumum size we need to grow by */
   at_least = chunk_size(at_least);

   /* Find the size of currently used memory */
   used = (size_t) mem->next - (size_t) mem->current;

   /* If doubling the memory isn't enough then the new size is the old_size + at_least */
   if (mem->size > at_least)
   {
      mem->size = mem->size * 2;
   }
   else
   {
      mem->size = mem->size + at_least;
   }

   /* Resize the inactive memory area */
   mem->inactive = resize_pointer(mem->size, mem->inactive);

   /* Resize the current memory region */
   mem->current = resize_pointer(mem->size, mem->current);

   /* Set the address of the next chunk */
   mem->next = (chunk *) ((size_t) mem->current + used);

   /* readdress the chunks in the current memory region */
   readdress(used, mem);
}

/* Readdress the chunks in current memory
   The arguments are currently used memory, and then the memory unit */
void readdress(size_t used, memory_manager mem)
{
   /* Pointer to the chunk we're working on */
   chunk * chnk;
 
   /* Loop through all the current chunks, updating their addresses */  
   CHUNK_LOOP(
         /* Set the address of the chunk to its own address */
      *(chnk->addr) = chnk;
   )
}

/* Create a new memory manager of given size */
memory_manager new_memory_manager(size_t size)
{
   /* The new memory manager */
   memory_manager mem;

   /* The size of the memory areas */
   size_t area_size;

   /* Set the size of the memory areas */
   area_size = size;

   /* Create the new memory manager */
   mem = (memory_manager) new_pointer(sizeof(amemory_manager));

   /* Initialize the memory manager */
   mem->current = (memory_area) new_pointer(area_size);
   mem->inactive = (memory_area) new_pointer(area_size);
   mem->next = (chunk *) mem->current;
   mem->size = area_size;
}

/* Free the addresses of every chunk */

/* Shutdown the memory manager */
void shutdown_memory_manager(memory_manager mem)
{
   /* The current chunk */
   chunk * chnk;

   /* Free the address of every chunk */
   CHUNK_LOOP(
      free(chnk->addr);
   )

   /* Free the memory areas */
   free(mem->current);
   free(mem->inactive);
}